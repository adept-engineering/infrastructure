#!/usr/bin/env bash
# Create admin-gated Adept Dev workspace (16 GB, full stack: Cursor, Claude Code, Antigravity, Devin).
# NOT added to All Users — assign per user with grant-dev-access.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
adept_log "Provisioning Adept Dev workspace"
python3 "${SCRIPT_DIR}/lib/provision_dev_workspaces.py"
if [[ -f "${SCRIPT_DIR}/../config/dev-access.env" ]]; then
  bash "${SCRIPT_DIR}/sync-dev-access.sh"
else
  adept_log "Done. Grant: ${SCRIPT_DIR}/grant-dev-access.sh <username>"
fi
