#!/usr/bin/env bash
# Provision adept-u01..u05 with auto-generated passwords (Kasm policy compliant).
#
# Usage:
#   export KASM_ADMIN_PASSWORD='...'
#   ./provision-adept-users.sh           # create missing users; keep existing passwords
#   ./provision-adept-users.sh --rotate  # reset all adept user passwords

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ROTATE=0
[[ "${1:-}" == "--rotate" ]] && ROTATE=1

create_user() {
  local user="$1" pass="$2" num="$3"
  local token
  token=$(adept_admin_token)
  curl -sk -X POST "${KASM_BASE}/api/admin/create_user" \
    -H 'Content-Type: application/json' \
    -d "{
      \"username\": \"${ADMIN_USER}\",
      \"token\": \"${token}\",
      \"target_user\": {
        \"username\": \"${user}\",
        \"password\": \"${pass}\",
        \"first_name\": \"Adept\",
        \"last_name\": \"U${num}\",
        \"locked\": false,
        \"disabled\": false
      }
    }" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('user',{}).get('username', d))"
}

update_password() {
  local user="$1" pass="$2"
  local token uid
  token=$(adept_admin_token)
  uid=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc "SELECT user_id FROM users WHERE username='${user}'")
  curl -sk -X POST "${KASM_BASE}/api/admin/update_user" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${ADMIN_USER}\",\"token\":\"${token}\",\"target_user\":{\"user_id\":\"${uid}\",\"username\":\"${user}\",\"password\":\"${pass}\"}}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'user' in d else 1)"
}

touch "$USERS_FILE"
chmod 600 "$USERS_FILE"

for i in 01 02 03 04 05; do
  user="${ADEPT_USER_PREFIX}${i}"
  exists=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc "SELECT 1 FROM users WHERE username='${user}'" || true)

  if [[ "$exists" == "1" && "$ROTATE" -eq 0 ]]; then
    pass=$(adept_user_password "$user")
    [[ -z "$pass" ]] && pass=$(adept_gen_password)
    adept_log "${user} exists (password unchanged unless missing from ${USERS_FILE})"
  else
    pass=$(adept_gen_password)
    if [[ "$exists" == "1" ]]; then
      update_password "$user" "$pass"
      adept_log "${user} password rotated"
    else
      create_user "$user" "$pass" "$i"
      adept_log "${user} created"
    fi
  fi

  if grep -q "^${user}=" "$USERS_FILE" 2>/dev/null; then
    sed -i "s|^${user}=.*|${user}=${pass}|" "$USERS_FILE"
  else
    echo "${user}=${pass}" >> "$USERS_FILE"
  fi
done

# Normalize legacy rename from earlier testing
if docker exec kasm_db psql -U kasmapp -d kasm -tAc "SELECT 1 FROM users WHERE username='adept-u05-renamed'" | grep -q 1; then
  if docker exec kasm_db psql -U kasmapp -d kasm -tAc "SELECT 1 FROM users WHERE username='adept-u05'" | grep -q 1; then
    docker exec kasm_db psql -U kasmapp -d kasm -q -c "DELETE FROM users WHERE username='adept-u05-renamed';"
  else
    token=$(adept_admin_token)
    uid=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc "SELECT user_id FROM users WHERE username='adept-u05-renamed'")
    pass=$(adept_gen_password)
    curl -sk -X POST "${KASM_BASE}/api/admin/update_user" \
      -H 'Content-Type: application/json' \
      -d "{\"username\":\"${ADMIN_USER}\",\"token\":\"${token}\",\"target_user\":{\"user_id\":\"${uid}\",\"username\":\"adept-u05\",\"password\":\"${pass}\"}}" >/dev/null
    echo "adept-u05=${pass}" >> "$USERS_FILE"
    adept_log "renamed adept-u05-renamed -> adept-u05"
  fi
fi

adept_log "Passwords saved to ${USERS_FILE}"
