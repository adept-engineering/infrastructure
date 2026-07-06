#!/usr/bin/env bash
# Start Kasm platform + Adept HTTP proxy. Safe to run after reboot.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

adept_log "Starting containerd/docker (if needed)"
sudo systemctl start containerd docker

adept_log "Starting Kasm platform"
sudo /opt/kasm/bin/start

adept_log "Applying resource governor"
bash "${SCRIPT_DIR}/resource-governor.sh"

adept_log "Ensuring host nginx (HTTPS entry on workspaces.adeptengr.com)"
if systemctl is-active --quiet nginx; then
  sudo nginx -t && sudo systemctl reload nginx
else
  adept_log "WARN: host nginx not running — run: sudo ${SCRIPT_DIR}/install-host-nginx.sh"
fi

adept_log "Ensuring zone proxy port (443 via host nginx)"
docker exec kasm_db psql -U kasmapp -d kasm -q -c \
  "UPDATE zones SET proxy_port = 443, proxy_hostname = '\$request_host\$' WHERE zone_name = 'default' AND proxy_port <> 443;"

adept_log "Applying Adept branding"
bash "${SCRIPT_DIR}/apply-branding.sh"

adept_log "Ensuring passwordless sudo in workspace containers"
bash "${SCRIPT_DIR}/enable-workspace-sudo.sh" --live

if [[ -f "${SCRIPT_DIR}/../config/dev-access.env" ]]; then
  adept_log "Syncing admin-gated Adept Dev workspace access"
  bash "${SCRIPT_DIR}/sync-dev-access.sh"
fi

adept_log "Running healthcheck"
bash "${SCRIPT_DIR}/healthcheck.sh"

adept_log "Ready: https://workspaces.adeptengr.com/"
