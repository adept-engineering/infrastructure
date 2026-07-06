#!/usr/bin/env bash
# Sync dev-access.env -> grant/revoke Adept Dev group membership.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADEPT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CFG="${ADEPT_ROOT}/config/dev-access.env"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ -f "$CFG" ]] || { echo "Missing $CFG" >&2; exit 1; }

python3 "${SCRIPT_DIR}/lib/provision_dev_workspaces.py" >/dev/null

want=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line// /}"
  [[ -n "$line" ]] && want+=("$line")
done < "$CFG"

have=()
while IFS= read -r u; do
  [[ -n "$u" ]] && have+=("$u")
done < <(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
  "SELECT u.username FROM users u
   JOIN user_groups ug ON u.user_id = ug.user_id
   JOIN groups g ON g.group_id = ug.group_id
   WHERE g.name = 'Adept Dev' ORDER BY 1;")

for u in "${want[@]}"; do
  if [[ " ${have[*]} " != *" $u "* ]]; then
    adept_log "grant $u"
    "${SCRIPT_DIR}/grant-dev-access.sh" "$u"
  fi
done

for u in "${have[@]}"; do
  if [[ " ${want[*]} " != *" $u "* ]]; then
    adept_log "revoke $u"
    "${SCRIPT_DIR}/revoke-dev-access.sh" "$u"
  fi
done

adept_log "Dev access synced from ${CFG}"
