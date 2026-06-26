#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

HTTP_BASE="${PUBLIC_URL:-https://workspaces.adeptengr.com}"
OUT="${ADEPT_ROOT}/logs/branding-browser-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

adept_log "Browser branding test -> ${HTTP_BASE}"

docker run --rm --network host \
  -e "HTTP_BASE=${HTTP_BASE}" \
  -e "OUT_DIR=/out" \
  -v "${OUT}:/out" \
  -v "${SCRIPT_DIR}/branding-browser-test.js:/test.js:ro" \
  -w /tmp/pw \
  mcr.microsoft.com/playwright:v1.49.1-jammy \
  bash -lc 'npm init -y >/dev/null 2>&1 && npm install playwright@1.49.1 --silent && cp /test.js ./test.js && node ./test.js' \
  2>&1 | tee "${OUT}/run.log"

if grep -q 'BROWSER PASS' "${OUT}/run.log"; then
  adept_log "PASS: headless browser login page branding"
  adept_log "Screenshot: ${OUT}/login.png"
  exit 0
fi

adept_log "FAIL: headless browser branding test — see ${OUT}/run.log"
exit 1
