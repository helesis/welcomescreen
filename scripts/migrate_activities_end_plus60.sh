#!/usr/bin/env bash
# end_hour/end_minute boş olan tüm aktivitelerde bitiş = başlangıç + 60 dk (gece taşması mod 24)
# Önce: ./pb_activities_end_fields.sh
set -euo pipefail
PB_URL="${PB_URL:-https://hotel-data.voyagestars.com}"
ADMIN_EMAIL="${PB_ADMIN_EMAIL:-}"
ADMIN_PASS="${PB_ADMIN_PASSWORD:-}"
[[ -z "$ADMIN_EMAIL" ]] && read -r -p "Admin e-posta: " ADMIN_EMAIL
[[ -z "$ADMIN_PASS" ]] && read -r -s -p "Admin şifre: " ADMIN_PASS && echo
TOKEN=$(curl -sS "${PB_URL}/api/admins/auth-with-password" -H "Content-Type: application/json" \
  -d "{\"identity\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\"}" | jq -r '.token')
[[ "$TOKEN" == "null" || -z "$TOKEN" ]] && { echo "Giriş hatası" >&2; exit 1; }

TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
curl -sS "${PB_URL}/api/collections/activities/records?perPage=500" \
  -H "Authorization: ${TOKEN}" > "$TMP"

N=0
while IFS= read -r row; do
  id=$(echo "$row" | jq -r '.id')
  h=$(echo "$row" | jq -r '.hour // 0')
  m=$(echo "$row" | jq -r '.minute // 0')
  eh=$(echo "$row" | jq -r '.end_hour')
  em=$(echo "$row" | jq -r '.end_minute')
  if [[ "$eh" != "null" && -n "$eh" ]] || [[ "$em" != "null" && -n "$em" ]]; then
    continue
  fi
  st=$((10#$h * 60 + 10#$m + 60))
  st=$((st % 1440))
  ehr=$((st / 60))
  emn=$((st % 60))
  HTTP=$(curl -sS -o /dev/null -w "%{http_code}" -X PATCH "${PB_URL}/api/collections/activities/records/${id}" \
    -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" \
    -d "{\"end_hour\":${ehr},\"end_minute\":${emn}}")
  if [[ "$HTTP" == "200" ]]; then
    echo "OK ${id}  ${h}:${m} -> ${ehr}:${emn}"
    N=$((N+1))
  else
    echo "FAIL ${id} HTTP $HTTP" >&2
  fi
done < <(jq -c '.items[]' "$TMP")

echo "Güncellenen kayıt: $N"
