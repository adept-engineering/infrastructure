#!/usr/bin/env bash
# Exit 0 if Adept Kasm stack is healthy; non-zero otherwise.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

FAIL=0
check() {
  local name="$1" rc="$2"
  if [[ "$rc" -ne 0 ]]; then
    adept_log "FAIL: ${name}"
    FAIL=1
  else
    adept_log "OK: ${name}"
  fi
}

http_code=$(curl -sk -o /dev/null -w '%{http_code}' "${PUBLIC_URL}/" --connect-timeout 10)
[[ "$http_code" == "200" ]]; check "HTTPS ${PUBLIC_URL}" $?

https_code=$(curl -sk -o /dev/null -w '%{http_code}' "${KASM_BASE}/" --connect-timeout 5)
[[ "$https_code" == "200" ]]; check "Kasm proxy ${KASM_HTTPS_PORT:-9443}" $?

for c in kasm_db kasm_api kasm_manager kasm_agent kasm_proxy; do
  if docker ps --format '{{.Names}}' | grep -qx "$c"; then
    check "container ${c}" 0
  else
    check "container ${c}" 1
  fi
done

root_pct=$(df / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
[[ "$root_pct" -lt 85 ]]; check "root disk ${root_pct}% used" $?

data_pct=$(df /data | awk 'NR==2 {gsub(/%/,"",$5); print $5}')
[[ "$data_pct" -lt 90 ]]; check "data disk ${data_pct}% used" $?

exit "$FAIL"
