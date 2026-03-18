#!/usr/bin/env bash
# activities koleksiyonuna schedule_slot (text) ekler: daytime | kids | evening
set -euo pipefail
PB_URL="${PB_URL:-https://hotel-data.voyagestars.com}"
ADMIN_EMAIL="${PB_ADMIN_EMAIL:-}"
ADMIN_PASS="${PB_ADMIN_PASSWORD:-}"
[[ -z "$ADMIN_EMAIL" ]] && read -r -p "Admin e-posta: " ADMIN_EMAIL
[[ -z "$ADMIN_PASS" ]] && read -r -s -p "Admin şifre: " ADMIN_PASS && echo
TOKEN=$(curl -sS "${PB_URL}/api/admins/auth-with-password" -H "Content-Type: application/json" \
  -d "{\"identity\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\"}" | jq -r '.token')
[[ "$TOKEN" == "null" || -z "$TOKEN" ]] && { echo "Giriş hatası" >&2; exit 1; }
CID=$(curl -sS "${PB_URL}/api/collections" -H "Authorization: ${TOKEN}" \
  | jq -r '.items[] | select(.name == "activities") | .id')
TMP=$(mktemp); TMP2=$(mktemp); trap 'rm -f "$TMP" "$TMP2"' EXIT
curl -sS "${PB_URL}/api/collections/${CID}" -H "Authorization: ${TOKEN}" > "$TMP"
if jq -e '.schema | map(.name) | index("schedule_slot") != null' "$TMP" >/dev/null 2>&1; then
  echo "schedule_slot alanı zaten mevcut."
  exit 0
fi
jq '.schema as $s | del(.schema) | . + {schema: ($s + [{"name":"schedule_slot","type":"text","required":false,"presentable":true}])}' "$TMP" > "$TMP2"
HTTP=$(curl -sS -o "$TMP" -w "%{http_code}" -X PATCH "${PB_URL}/api/collections/${CID}" \
  -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" -d @"$TMP2")
[[ "$HTTP" == "200" ]] && { jq . "$TMP"; echo "schedule_slot eklendi."; } || { echo "HTTP $HTTP" >&2; cat "$TMP"; exit 1; }
