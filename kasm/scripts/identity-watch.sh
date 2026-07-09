#!/usr/bin/env bash
# Runs patch-session-identity.sh every 15s within a 1-minute cron tick, so a
# fresh session shows the real username within ~15s instead of waiting for
# resource-governor.sh's 2-minute cycle.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for _ in 1 2 3 4; do
  bash "${SCRIPT_DIR}/patch-session-identity.sh" || true
  sleep 15
done
