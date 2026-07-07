#!/usr/bin/env bash
# Create a Kasm user with email login (admin API). CE has no self-service signup.
#
# Usage:
#   source ~/workspace/kasm/.env
#   ./create-user.sh email@adeptengr.com 'First' 'Last' ['Password']
#
# If password omitted, one is generated and printed.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

[[ $# -ge 3 ]] || { echo "Usage: $0 <email> <first_name> <last_name> [password]" >&2; exit 1; }

EMAIL="$1"
FIRST="$2"
LAST="$3"
PASS="${4:-$(adept_gen_password)}"

token=$(adept_admin_token)
resp=$(curl -sk -X POST "${KASM_BASE}/api/admin/create_user" \
  -H 'Content-Type: application/json' \
  -d "{
    \"username\": \"${ADMIN_USER}\",
    \"token\": \"${token}\",
    \"target_user\": {
      \"username\": \"${EMAIL}\",
      \"email\": \"${EMAIL}\",
      \"password\": \"${PASS}\",
      \"first_name\": \"${FIRST}\",
      \"last_name\": \"${LAST}\",
      \"locked\": false,
      \"disabled\": false
    }
  }")

python3 - "$resp" "$EMAIL" "$PASS" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
email, pw = sys.argv[2], sys.argv[3]
if "user" not in d:
    print("FAILED:", d, file=sys.stderr)
    sys.exit(1)
print(f"Created: {email}")
print(f"Password: {pw}")
PY

adept_log "Assigning RAM tier (if configured in config/user-resources.env)"
if [[ -f "${SCRIPT_DIR}/../config/user-resources.env" ]]; then
  bash "${SCRIPT_DIR}/apply-user-resources.sh"
fi
adept_log "Identity (whoami) applies automatically on first workspace launch for all users"
