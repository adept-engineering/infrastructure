#!/usr/bin/env bash
# Shared helpers for Adept Kasm automation scripts.

set -euo pipefail

ADEPT_ROOT="${ADEPT_ROOT:-${HOME}/workspace/kasm}"
# shellcheck source=/dev/null
[[ -f "${ADEPT_ROOT}/.env" ]] && source "${ADEPT_ROOT}/.env"
# shellcheck source=/dev/null
[[ -f "${ADEPT_ROOT}/config/adept.defaults.env" ]] && source "${ADEPT_ROOT}/config/adept.defaults.env"

PUBLIC_URL="${PUBLIC_URL:-https://workspaces.adeptengr.com}"
SERVER_IP="${SERVER_IP:-$(hostname -I | awk '{print $1}')}"
KASM_BASE="https://${SERVER_IP}:${KASM_HTTPS_PORT:-9443}"
ADMIN_USER="${KASM_ADMIN_USER:-admin@kasm.local}"
ADMIN_PASS="${KASM_ADMIN_PASSWORD:-}"
USERS_FILE="${ADEPT_ROOT}/.adept-users.env"

adept_gen_password() {
  local base
  base=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 14)
  printf '%s!%s' "$base" "$(printf '%02d' $((RANDOM % 90 + 10)))"
}

adept_admin_token() {
  [[ -n "$ADMIN_PASS" ]] || { echo "KASM_ADMIN_PASSWORD not set" >&2; return 1; }
  curl -sk -X POST "${KASM_BASE}/api/authenticate" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${ADMIN_USER}\",\"password\":\"${ADMIN_PASS}\"}" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])"
}

adept_user_token() {
  local user="$1" pass="$2"
  curl -sk -X POST "${KASM_BASE}/api/authenticate" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${user}\",\"password\":\"${pass}\"}" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))"
}

adept_running_session_count() {
  docker exec kasm_db psql -U kasmapp -d kasm -tAc \
    "SELECT COUNT(*) FROM kasms WHERE operational_status IN ('running','starting');" 2>/dev/null || echo 0
}

adept_image_id() {
  local name="$1"
  docker exec kasm_db psql -U kasmapp -d kasm -tAc \
    "SELECT image_id FROM images WHERE friendly_name='${name}';"
}

adept_user_password() {
  local user="$1"
  grep "^${user}=" "$USERS_FILE" 2>/dev/null | cut -d= -f2- || true
}

adept_log() {
  printf '[%s] %s\n' "$(date -Iseconds)" "$*"
}

adept_wait_agent_ready() {
  local i status
  for ((i=1; i<=45; i++)); do
    status=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
      "SELECT operational_status FROM servers LIMIT 1;" 2>/dev/null || echo "")
    if [[ "$status" == "running" ]]; then
      sleep 5
      return 0
    fi
    sleep 2
  done
  return 1
}
