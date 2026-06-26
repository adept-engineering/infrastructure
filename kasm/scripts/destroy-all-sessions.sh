#!/usr/bin/env bash
# Destroy all Kasm workspace sessions via admin API.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ADMTOK=$(adept_admin_token)

mapfile -t KASM_IDS < <(curl -sk -X POST "${KASM_BASE}/api/admin/get_kasms" \
  -H 'Content-Type: application/json' \
  -d "{\"username\":\"${ADMIN_USER}\",\"token\":\"${ADMTOK}\"}" \
  | python3 -c "import sys,json; print('\n'.join(k['kasm_id'] for k in json.load(sys.stdin).get('kasms',[])))")

for kid in "${KASM_IDS[@]}"; do
  [[ -z "$kid" ]] && continue
  curl -sk -X POST "${KASM_BASE}/api/admin/destroy_kasm" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${ADMIN_USER}\",\"token\":\"${ADMTOK}\",\"kasm_id\":\"${kid}\"}" >/dev/null
  adept_log "destroyed ${kid}"
done

sleep 10
remaining=$(adept_running_session_count)
adept_log "remaining sessions: ${remaining}"
