#!/usr/bin/env bash
# Show Kasm login name in whoami (not only kasm-user) + passwordless sudo.
#
# Requires: expose_user_environment_vars on All Users group
# Users must start a NEW session after apply (or use --live on running containers).
#
# Usage:
#   ./apply-user-identity.sh
#   ./apply-user-identity.sh --live

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

LIVE=0
[[ "${1:-}" == "--live" ]] && LIVE=1

ALL_USERS_GROUP_ID="68d557ac-4cac-42cc-a9f3-1c7c853de0f3"
EXEC_JSON=$(python3 "${SCRIPT_DIR}/lib/adept_exec_config.py")
EXEC_SQL=${EXEC_JSON//\'/\'\'}

adept_log "Enabling expose_user_environment_vars on All Users group"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "DELETE FROM group_settings WHERE group_id = '${ALL_USERS_GROUP_ID}' AND name = 'expose_user_environment_vars';
   INSERT INTO group_settings (group_setting_id, name, value, value_type, description, group_id)
   VALUES (uuid_generate_v4(), 'expose_user_environment_vars', 'True', 'bool',
           'Expose KASM_USER to session containers (Adept identity)', '${ALL_USERS_GROUP_ID}');"

adept_log "Applying exec_config to Desktop images (RAM tiers; skips Adept Dev —*)"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "UPDATE images SET exec_config = '${EXEC_SQL}'::json
   WHERE image_type = 'Container' AND categories::text ILIKE '%Desktop%'
     AND friendly_name NOT LIKE 'Adept Dev%';"

patch_container() {
  local cname="$1" kasm_user
  kasm_user=$(docker exec "$cname" bash -lc 'echo -n "$KASM_USER"' 2>/dev/null || true)
  [[ -n "$kasm_user" ]] || return 1
  docker exec -u root -e KASM_USER="$kasm_user" "$cname" bash -c \
    'u=$(echo "$KASM_USER" | sed -r "s#[^a-zA-Z0-9._-]#_#g" | cut -c1-32)
     grep -q "kasm-user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null || echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
     if [ -n "$u" ] && [ "$u" != "kasm-user" ] && id kasm-user >/dev/null 2>&1; then
       usermod -l "$u" kasm-user 2>/dev/null || true
       getent group kasm-user >/dev/null 2>&1 && groupmod -n "$u" kasm-user 2>/dev/null || true
     fi' 2>/dev/null || return 1
  docker exec "$cname" bash -lc 'whoami' 2>/dev/null
}

if [[ "$LIVE" -eq 1 ]]; then
  adept_log "Patching running session containers"
  while read -r cname; do
    [[ -n "$cname" ]] || continue
    who=$(patch_container "$cname" || echo "")
    if [[ -n "$who" ]]; then
      adept_log "  OK ${cname} -> whoami=${who}"
    else
      adept_log "  SKIP ${cname}"
    fi
  done < <(docker ps --format '{{.Names}}' | grep -vE '^kasm_' || true)
fi

adept_log "Done. New sessions: whoami matches Kasm username (emails sanitized to underscores)."
