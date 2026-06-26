#!/usr/bin/env bash
# Static API/asset checks + headless browser login page validation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/test-branding.sh"
"${SCRIPT_DIR}/test-branding-browser.sh"
