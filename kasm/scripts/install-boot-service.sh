#!/usr/bin/env bash
# Install systemd boot service to re-apply Kasm/Adept config after every reboot.
set -euo pipefail

ADEPT_ROOT="${HOME}/workspace/kasm"
UNIT_PATH="/etc/systemd/system/adept-kasm-boot.service"

sudo tee "${UNIT_PATH}" >/dev/null <<EOF
[Unit]
Description=Adept Kasm post-boot bootstrap
After=network-online.target docker.service containerd.service
Wants=network-online.target

[Service]
Type=oneshot
User=${USER}
WorkingDirectory=${ADEPT_ROOT}
ExecStart=/usr/bin/bash -lc 'sleep 45 && ${ADEPT_ROOT}/scripts/start-all.sh >> ${ADEPT_ROOT}/logs/reboot-start.log 2>&1'
TimeoutStartSec=900
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable adept-kasm-boot.service
echo "Installed and enabled: adept-kasm-boot.service"
