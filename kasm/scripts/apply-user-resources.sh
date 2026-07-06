#!/usr/bin/env bash
# Per-user RAM — see config/user-resources.env and docs/22-user-identity-and-ram.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADEPT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

CFG="${ADEPT_ROOT}/config/user-resources.env"
[[ -f "$CFG" ]] || { echo "Missing $CFG — copy from config/user-resources.env" >&2; exit 1; }

adept_log "Applying per-user RAM tiers"
python3 "${SCRIPT_DIR}/lib/sync_user_resources.py" "$CFG"
adept_log "Users must launch 'Ubuntu Jammy (<size>)' tile matching their tier (old hidden Ubuntu Jammy ends)"
