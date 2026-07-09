#!/usr/bin/env bash
# Show Kasm login name in whoami (not only kasm-user) + passwordless sudo.
# Applies to ALL users and ALL container workspaces (Desktop, VS Code, Terminal, etc.).
#
# Requires: expose_user_environment_vars on all groups
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

if [[ -x "${SCRIPT_DIR}/clean-profile-bashrc.sh" ]]; then
  adept_log "Cleaning Adept hooks from persisted profile .bashrc files"
  bash "${SCRIPT_DIR}/clean-profile-bashrc.sh"
fi

BASE_EXEC_JSON=$(python3 "${SCRIPT_DIR}/lib/adept_exec_config.py")
BASE_EXEC_SQL=${BASE_EXEC_JSON//\'/\'\'}
DEV_EXEC_JSON=$(python3 "${SCRIPT_DIR}/lib/adept_exec_config.py" adept-dev)
DEV_EXEC_SQL=${DEV_EXEC_JSON//\'/\'\'}

adept_log "Enabling expose_user_environment_vars on all groups"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "DELETE FROM group_settings WHERE name = 'expose_user_environment_vars';
   INSERT INTO group_settings (group_setting_id, name, value, value_type, description, group_id)
   SELECT uuid_generate_v4(), 'expose_user_environment_vars', 'True', 'bool',
          'Expose KASM_USER to session containers (Adept identity)', group_id
   FROM groups;"

adept_log "Applying identity exec_config to all container workspaces (except Adept Dev)"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "UPDATE images SET exec_config = '${BASE_EXEC_SQL}'::json
   WHERE image_type = 'Container'
     AND friendly_name NOT LIKE 'Adept Dev%';"

adept_log "Applying exec_config to Adept Dev workspace"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "UPDATE images SET exec_config = '${DEV_EXEC_SQL}'::json
   WHERE friendly_name LIKE 'Adept Dev%';"

if [[ "$LIVE" -eq 1 ]]; then
  adept_log "Patching all running session containers"
  bash "${SCRIPT_DIR}/patch-session-identity.sh"
fi

adept_log "Done. All users: whoami matches Kasm username on every workspace type."
