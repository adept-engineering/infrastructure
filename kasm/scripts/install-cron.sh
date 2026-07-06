#!/usr/bin/env bash
# Install cron jobs for resource governor and daily health log.

set -euo pipefail
ADEPT_ROOT="${HOME}/workspace/kasm"
MARKER="# adept-kasm-automation"

(crontab -l 2>/dev/null | grep -v "$MARKER" || true
 echo "*/2 * * * * ${ADEPT_ROOT}/scripts/resource-governor.sh >> ${ADEPT_ROOT}/logs/governor.log 2>&1 ${MARKER}"
 echo "0 */6 * * * ${ADEPT_ROOT}/scripts/healthcheck.sh >> ${ADEPT_ROOT}/logs/health.log 2>&1 ${MARKER}"
) | crontab -

if [[ -x /usr/local/bin/renew-workspaces-certs.sh ]]; then
  (sudo crontab -l 2>/dev/null | grep -v "$MARKER" || true
   echo "50 2 * * * /usr/local/bin/renew-workspaces-certs.sh ${MARKER}"
  ) | sudo crontab -
  echo "Root cron: TLS renewal daily at 02:50."
fi

echo "Cron installed. Governor runs every 2 minutes."
