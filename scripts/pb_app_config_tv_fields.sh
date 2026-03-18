#!/usr/bin/env bash
# PocketBase app_config koleksiyonuna TV harita/program alanlarını ekler.
# Gereksinim: curl, jq  (Mac: brew install jq)
#
# Kullanım:
#   export PB_URL="https://your-pocketbase.example.com"   # varsayılan: hotel-data.voyagestars.com
#   ./scripts/pb_app_config_tv_fields.sh
#
# İsteğe bağlı (şifreyi sormaz):
#   export PB_ADMIN_EMAIL="you@example.com"
#   export PB_ADMIN_PASSWORD="secret"

set -euo pipefail

PB_URL="${PB_URL:-https://hotel-data.voyagestars.com}"
ADMIN_EMAIL="${PB_ADMIN_EMAIL:-}"
ADMIN_PASS="${PB_ADMIN_PASSWORD:-}"

if [[ -z "$ADMIN_EMAIL" ]]; then
  read -r -p "PocketBase admin e-posta: " ADMIN_EMAIL
fi
if [[ -z "$ADMIN_PASS" ]]; then
  read -r -s -p "Admin şifre: " ADMIN_PASS
  echo
fi

TOKEN=$(curl -sS "${PB_URL}/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\"}" | jq -r '.token')

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
  echo "Hata: Giriş başarısız (e-posta/şifre veya PB_URL)." >&2
  exit 1
fi

CID=$(curl -sS "${PB_URL}/api/collections" -H "Authorization: ${TOKEN}" \
  | jq -r '.items[] | select(.name == "app_config") | .id')

if [[ -z "$CID" || "$CID" == "null" ]]; then
  echo "Hata: app_config koleksiyonu bulunamadı." >&2
  exit 1
fi

TMP=$(mktemp)
TMP2=$(mktemp)
trap 'rm -f "$TMP" "$TMP2"' EXIT

curl -sS "${PB_URL}/api/collections/${CID}" -H "Authorization: ${TOKEN}" > "$TMP"

NEW_FIELDS='[
  {"name":"map_schedule_map_sec","type":"number","required":false,"presentable":false},
  {"name":"map_schedule_schedule_sec","type":"number","required":false,"presentable":false},
  {"name":"schedule_daytime_activity_ids","type":"json","required":false,"presentable":false,"options":{"maxSize":2000000}},
  {"name":"schedule_kids_activity_ids","type":"json","required":false,"presentable":false,"options":{"maxSize":2000000}},
  {"name":"schedule_resto_use_all","type":"bool","required":false,"presentable":false},
  {"name":"schedule_resto_ids","type":"json","required":false,"presentable":false,"options":{"maxSize":2000000}},
  {"name":"schedule_evening_kids_show","type":"text","required":false,"presentable":false},
  {"name":"schedule_evening_main_show","type":"text","required":false,"presentable":false},
  {"name":"schedule_evening_after_show","type":"text","required":false,"presentable":false}
]'

MERGED=$(jq --argjson new "$NEW_FIELDS" '
  .schema as $s |
  ($new | map(select(.name as $n | (($s | map(.name)) | index($n) == null)))) as $toadd |
  { toadd: $toadd, patch: (. | del(.schema) | . + {schema: ($s + $toadd)}) }
' "$TMP")

TOADD_LEN=$(echo "$MERGED" | jq '.toadd | length')
if [[ "$TOADD_LEN" -eq 0 ]]; then
  echo "Tüm TV alanları zaten app_config içinde. Yeni ekleme gerekmedi."
  exit 0
fi

echo "$MERGED" | jq '.patch' > "$TMP2"

HTTP=$(curl -sS -o "$TMP" -w "%{http_code}" -X PATCH "${PB_URL}/api/collections/${CID}" \
  -H "Authorization: ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @"$TMP2")

if [[ "$HTTP" != "200" ]]; then
  echo "PATCH hatası HTTP $HTTP" >&2
  cat "$TMP" | jq . 2>/dev/null || cat "$TMP"
  exit 1
fi

jq . "$TMP"
echo "Tamam: ${TOADD_LEN} yeni alan app_config şemasına eklendi."
