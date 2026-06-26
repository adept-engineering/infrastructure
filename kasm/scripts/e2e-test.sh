#!/usr/bin/env bash
# Full end-to-end validation for Adept Kasm on Desktop-server.
#
# Tests: healthcheck, autoset passwords, resource governor (5 vs 3 users),
# five concurrent workspace sessions, three-session surplus RAM, external HTTP.
#
# Usage: source ~/workspace/kasm/.env && ./e2e-test.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

LOG="${ADEPT_ROOT}/logs/e2e-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${ADEPT_ROOT}/logs"

declare -A IMAGE_MAP=(
  ["adept-u01"]="Ubuntu Noble"
  ["adept-u02"]="Ubuntu Jammy"
  ["adept-u03"]="Terminal"
  ["adept-u04"]="Visual Studio Code"
  ["adept-u05"]="Firefox"
)

FAIL=0
ok() { adept_log "PASS: $*"; }
bad() { adept_log "FAIL: $*"; FAIL=1; }

request_kasm() {
  local user="$1" pw="$2" image_id="$3" token resp attempt
  for attempt in 1 2 3 4 5 6; do
    token=$(adept_user_token "$user" "$pw")
    resp=$(curl -sk -X POST "${KASM_BASE}/api/request_kasm" \
      -H 'Content-Type: application/json' \
      -d "{\"username\":\"${user}\",\"token\":\"${token}\",\"image_id\":\"${image_id}\"}")
    echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('kasm_id') else 1)" 2>/dev/null && { echo "$resp"; return 0; }
    sleep 10
  done
  echo "$resp"
}

wait_running() {
  local user="$1" pw="$2" kasm_id="$3" token status i
  token=$(adept_user_token "$user" "$pw")
  for ((i=1; i<=72; i++)); do
    status=$(curl -sk -X POST "${KASM_BASE}/api/get_kasm_status" \
      -H 'Content-Type: application/json' \
      -d "{\"username\":\"${user}\",\"token\":\"${token}\",\"kasm_id\":\"${kasm_id}\"}" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('kasm',{}).get('operational_status', d.get('error_message','?')))")
    [[ "$status" == "running" ]] && return 0
    [[ "$status" == "error" ]] && return 1
    sleep 5
  done
  return 1
}

launch_users() {
  local -n users_ref=$1
  local -n ids_ref=$2
  local user pw img_name image_id resp kasm_id
  for user in "${users_ref[@]}"; do
    pw=$(adept_user_password "$user")
    img_name="${IMAGE_MAP[$user]}"
    image_id=$(adept_image_id "$img_name")
    resp=$(request_kasm "$user" "$pw" "$image_id")
    kasm_id=$(echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin).get('kasm_id',''))" 2>/dev/null || true)
    if [[ -z "$kasm_id" ]]; then
      bad "${user} session create: ${resp}"
      ids_ref[$user]=""
      continue
    fi
    ids_ref[$user]="$kasm_id"
    adept_log "${user} -> ${img_name} (${kasm_id:0:8}…)"
  done
}

wait_all_running() {
  local -n users_ref=$1
  local -n ids_ref=$2
  local user pw kid
  for user in "${users_ref[@]}"; do
    pw=$(adept_user_password "$user")
    kid="${ids_ref[$user]}"
    [[ -z "$kid" ]] && continue
    if wait_running "$user" "$pw" "$kid"; then ok "$user session running"
    else bad "$user session not running"; fi
  done
}

image_memory_mib() {
  docker exec kasm_db psql -U kasmapp -d kasm -tAc \
    "SELECT (memory/1024/1024)::int FROM images WHERE friendly_name='$1';"
}

{
adept_log "=== Adept Kasm E2E ${SERVER_IP} ==="

adept_log "--- Phase 1: healthcheck ---"
if bash "${SCRIPT_DIR}/healthcheck.sh"; then ok healthcheck; else bad healthcheck; fi

adept_log "--- Phase 2: autoset passwords ---"
bash "${SCRIPT_DIR}/provision-adept-users.sh" --rotate
for i in 01 02 03 04 05; do
  user="${ADEPT_USER_PREFIX}${i}"
  pw=$(adept_user_password "$user")
  [[ -n "$pw" ]] && ok "autoset password ${user}" || bad "missing password ${user}"
  tok=$(adept_user_token "$user" "$pw")
  [[ -n "$tok" ]] && ok "login ${user}" || bad "login ${user}"
done

for img in $ADEPT_WORKSPACE_IMAGES; do
  docker exec kasm_db psql -U kasmapp -d kasm -q -c \
    "UPDATE images SET persistent_profile_path='${ADEPT_PROFILES_PATH}' WHERE friendly_name='${img}';"
done

adept_log "--- Phase 3: clean slate ---"
bash "${SCRIPT_DIR}/destroy-all-sessions.sh"

adept_log "--- Phase 4: five concurrent sessions ---"
bash "${SCRIPT_DIR}/resource-governor.sh"
adept_wait_agent_ready || bad "agent not ready"
mem5=$(image_memory_mib "Ubuntu Noble")
adept_log "planned RAM Ubuntu Noble=${mem5}MiB (${ADEPT_MAX_SESSIONS} slots)"

declare -a USERS5=(adept-u01 adept-u02 adept-u03 adept-u04 adept-u05)
declare -A IDS5=()
launch_users USERS5 IDS5
wait_all_running USERS5 IDS5

running=$(adept_running_session_count)
total_mib=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
used_avail=$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)
[[ "$running" -eq 5 ]] && ok "5 concurrent sessions" || bad "expected 5 sessions, got ${running}"

used_pct=$(( (total_mib - used_avail) * 100 / total_mib ))
[[ "$used_pct" -lt 90 ]] && ok "RAM ${used_pct}% used" || bad "RAM ${used_pct}% too high"

adept_log "--- Phase 5: three sessions (surplus RAM) ---"
bash "${SCRIPT_DIR}/destroy-all-sessions.sh"
bash "${SCRIPT_DIR}/resource-governor.sh"
adept_wait_agent_ready || bad "agent not ready"

declare -a USERS3=(adept-u01 adept-u02 adept-u03)
declare -A IDS3=()
launch_users USERS3 IDS3
wait_all_running USERS3 IDS3

bash "${SCRIPT_DIR}/resource-governor.sh"
mem3=$(image_memory_mib "Ubuntu Noble")
[[ "$mem3" -gt "$mem5" ]] && ok "3-user RAM ${mem3}MiB > 5-user plan ${mem5}MiB" || bad "RAM scaling"

adept_log "--- Phase 6: external HTTPS ---"
code=$(curl -sk -o /dev/null -w '%{http_code}' "${PUBLIC_URL:-https://workspaces.adeptengr.com}/")
[[ "$code" == "200" ]] && ok "${PUBLIC_URL:-https://workspaces.adeptengr.com}" || bad "external HTTPS"

docker ps --format '{{.Names}}' | grep -c '^adept-u' | while read -r n; do adept_log "session containers: ${n}"; done
free -h | head -2

if [[ "$FAIL" -eq 0 ]]; then adept_log "=== E2E PASSED ==="; exit 0; fi
adept_log "=== E2E FAILED ==="
exit 1
} 2>&1 | tee "$LOG"
