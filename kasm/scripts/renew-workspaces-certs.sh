#!/usr/bin/env bash
set -euo pipefail
CERT_NAME="adept-workspaces-unified"
LOG_FILE="/var/log/adept-workspaces-ssl.log"
NGINX_SSL_BASE="/etc/nginx/ssl/workspaces.adeptengr.com"
LE_LIVE_PATH="/etc/letsencrypt/live/${CERT_NAME}"

log() { echo "[$(date -Iseconds)] [RENEW] $*" | tee -a "$LOG_FILE"; }

[[ $EUID -eq 0 ]] || exit 1
certbot renew --cert-name "$CERT_NAME" --quiet >>"$LOG_FILE" 2>&1 || { log "renew failed"; exit 1; }

if [[ -d "$LE_LIVE_PATH" ]]; then
  mkdir -p "$NGINX_SSL_BASE"
  ln -sf "$LE_LIVE_PATH/fullchain.pem" "$NGINX_SSL_BASE/fullchain.crt"
  ln -sf "$LE_LIVE_PATH/privkey.pem"   "$NGINX_SSL_BASE/private.key"
  ln -sf "$LE_LIVE_PATH/chain.pem"     "$NGINX_SSL_BASE/chain.crt"
  ln -sf "$LE_LIVE_PATH/cert.pem"      "$NGINX_SSL_BASE/cert.crt"
fi

nginx -t >>"$LOG_FILE" 2>&1 && systemctl reload nginx >>"$LOG_FILE" 2>&1
log "renewal complete"
