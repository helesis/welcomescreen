#!/usr/bin/env bash
# Mevcut activities kayıtlarını hour/minute/end_hour/end_minute'dan start/end (text) formatına dönüştürür.
# Önce pb_activities_start_end.sh çalıştırılmalı.
set -euo pipefail
PB_URL="${PB_URL:-https://hotel-data.voyagestars.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-${PB_ADMIN_EMAIL:-}}"
ADMIN_PASS="${ADMIN_PASSWORD:-${PB_ADMIN_PASSWORD:-}}"
[[ -z "$ADMIN_EMAIL" ]] && read -r -p "Admin e-posta: " ADMIN_EMAIL
[[ -z "$ADMIN_PASS" ]] && read -r -s -p "Admin şifre: " ADMIN_PASS && echo

TOKEN=$(curl -sS "${PB_URL}/api/admins/auth-with-password" -H "Content-Type: application/json" \
  -d "{\"identity\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASS}\"}" | jq -r '.token')
[[ "$TOKEN" == "null" || -z "$TOKEN" ]] && { echo "Giriş hatası" >&2; exit 1; }

DATA=$(curl -sS "${PB_URL}/api/collections/activities/records?perPage=500" -H "Authorization: ${TOKEN}")
COUNT=0
while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  id=$(echo "$row" | jq -r '.id')
  start_val=$(echo "$row" | jq -r '.start')
  if [[ -n "$start_val" && "$start_val" != "null" ]]; then
    continue
  fi
  h=$(echo "$row" | jq -r '.hour // 0')
  m=$(echo "$row" | jq -r '.minute // 0')
  start_str=$(printf '%02d:%02d' "$((h))" "$((m))")
  eh=$(echo "$row" | jq -r '.end_hour')
  em=$(echo "$row" | jq -r '.end_minute')
  if [[ "$eh" == "null" || -z "$eh" ]]; then
    t=$((h*60+m+60))
    x=$(((t%1440+1440)%1440))
    eh=$((x/60))
    em=$((x%60))
  fi
  end_str=$(printf '%02d:%02d' "$((eh))" "$((em))")
  curl -sS -X PATCH "${PB_URL}/api/collections/activities/records/${id}" \
    -H "Authorization: ${TOKEN}" -H "Content-Type: application/json" \
    -d "{\"start\":\"${start_str}\",\"end\":\"${end_str}\"}" > /dev/null
  echo "  $id -> start=$start_str end=$end_str"
  COUNT=$((COUNT+1))
done
echo "Toplam $COUNT kayıt güncellendi."
