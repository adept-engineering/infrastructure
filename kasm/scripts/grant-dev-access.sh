#!/usr/bin/env bash
# Grant a user access to Adept Dev workspaces (admin-gated).
# Usage: ./grant-dev-access.sh remikuti
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -eq 1 ]] || { echo "Usage: $0 <kasm-username>" >&2; exit 1; }
USER="$1"
GROUP_NAME="Adept Dev"

uid=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
  "SELECT user_id FROM users WHERE username = '${USER//\'/\'\'}';")
[[ -n "$uid" ]] || { echo "User not found: $USER" >&2; exit 1; }

gid=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
  "SELECT group_id FROM groups WHERE name = '${GROUP_NAME}' LIMIT 1;")
[[ -n "$gid" ]] || { echo "Run ./provision-dev-workspaces.sh first" >&2; exit 1; }

docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -q -c \
  "DELETE FROM user_groups WHERE user_id = '${uid}' AND group_id = '${gid}';
   INSERT INTO user_groups (user_group_id, user_id, group_id)
   VALUES (uuid_generate_v4(), '${uid}', '${gid}')
   ON CONFLICT DO NOTHING;"

adept_log "Granted '${GROUP_NAME}' to ${USER}"
adept_log "User will see workspace tile: Adept Dev (16 GB, full tool stack)"
