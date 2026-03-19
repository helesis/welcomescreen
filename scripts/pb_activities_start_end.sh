#!/usr/bin/env bash
# activities koleksiyonuna start, end (text) ekler — restoranlardaki opens/closes gibi
# Örn. "09:00", "11:30", "23:00", "01:00"
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
[[ -z "$CID" || "$CID" == "null" ]] && { echo "activities koleksiyonu bulunamadı" >&2; exit 1; }
TMP=$(mktemp); TMP2=$(mktemp); trap 'rm -f "$TMP" "$TMP2"' EXIT
curl -sS "${PB_URL}/api/collections/${CID}" -H "Authorization: ${TOKEN}" > "$TMP"
NEW='[
  {"name":"start","type":"text","required":false,"presentable":true},
  {"name":"end","type":"text","required":false,"presentable":true}
]'
MERGED=$(jq --argjson new "$NEW" '
  .schema as $s |
  ($new | map(select(.name as $n | (($s | map(.name)) | index($n) == null)))) as $toadd |
  { toadd: $toadd, patch: (. | del(.schema) | . + {schema: ($s + $toadd)}) }
' "$TMP")
TOADD_LEN=$(echo "$MERGED" | jq '.toadd | length')
if [[ "$TOADD_LEN" -eq 0 ]]; then
  echo "start / end zaten tanımlı."
  exit 0
fi
echo "$MERGED" | jq '.patch' > "$TMP2"
HTTP=$(curl -sS -o "$TMP" -w "%{http_code}" -X PATCH "${PB_URL}/api/collections/${CID}" \
  -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" -d @"$TMP2")
[[ "$HTTP" == "200" ]] && { echo "Tamam: start, end (text) eklendi."; jq .schema "$TMP" 2>/dev/null || true; } || { echo "HTTP $HTTP" >&2; cat "$TMP"; exit 1; }
