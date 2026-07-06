#!/usr/bin/env bash
# Adjust per-workspace CPU/RAM in Kasm DB based on how many sessions are active.
# New sessions pick up updated limits; running sessions keep their original allocation.
#
# Usage: resource-governor.sh [--dry-run]
# Schedule: every 2 minutes via cron (see install-cron.sh)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

total_mib=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
active=$(adept_running_session_count)
if [[ "$active" -eq 0 ]]; then
  planning_slots=${ADEPT_MAX_SESSIONS}
else
  planning_slots=$(( ADEPT_MAX_SESSIONS - active ))
fi
[[ "$planning_slots" -lt 1 ]] && planning_slots=1

allocable=$(( total_mib - ADEPT_PLATFORM_RESERVE_MIB ))
per_session=$(( allocable / planning_slots ))
[[ "$per_session" -gt "$ADEPT_MAX_SESSION_MIB" ]] && per_session=$ADEPT_MAX_SESSION_MIB
[[ "$per_session" -lt "$ADEPT_MIN_SESSION_MIB" ]] && per_session=$ADEPT_MIN_SESSION_MIB

if [[ "$active" -le 3 ]]; then
  cores_desktop=2
  cores_light=1
else
  cores_desktop=1
  cores_light=1
fi

per_session_bytes=$(( per_session * 1024 * 1024 ))

adept_log "RAM total=${total_mib}MiB active=${active} planning_slots=${planning_slots} -> ${per_session}MiB/session cores_desktop=${cores_desktop}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "dry-run: would set memory=${per_session_bytes} bytes"
  exit 0
fi

docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "UPDATE images SET memory = ${per_session_bytes}, cores = ${cores_desktop}
   WHERE friendly_name IN ('Ubuntu Noble', 'Ubuntu Jammy', 'Visual Studio Code')
     AND friendly_name NOT LIKE '%(%GB)%' AND friendly_name NOT LIKE '%(%MB)%'
     AND friendly_name NOT LIKE 'Adept Dev%';"

docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "UPDATE images SET memory = $(( per_session_bytes * 3 / 4 )), cores = ${cores_light}
   WHERE friendly_name IN ('Terminal', 'Firefox');"

docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "UPDATE servers SET max_simultaneous_sessions = ${ADEPT_MAX_SESSIONS};"
