#!/usr/bin/env bash
# Issue or expand Let's Encrypt cert for workspaces.adeptengr.com
set -euo pipefail

CERT_NAME="adept-workspaces-unified"
DOMAIN_CONFIG="/etc/letsencrypt/configs/workspaces-domains.conf"
EMAIL_CONFIG="/etc/letsencrypt/configs/workspaces-email.conf"
LOG_FILE="/var/log/adept-workspaces-ssl.log"
NGINX_SSL_BASE="/etc/nginx/ssl/workspaces.adeptengr.com"
LE_LIVE_PATH="/etc/letsencrypt/live/${CERT_NAME}"
WEBROOT="/var/www/certbot/workspaces.adeptengr.com"
ADEPT_ROOT="/home/ubuntu/workspace/kasm"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

[[ $EUID -eq 0 ]] || { echo "Run with sudo" >&2; exit 1; }
command -v certbot >/dev/null || { echo "Install certbot first" >&2; exit 1; }
[[ -f "$EMAIL_CONFIG" ]] || { echo "Missing $EMAIL_CONFIG" >&2; exit 1; }
# shellcheck source=/dev/null
source "$EMAIL_CONFIG"
[[ -f "$DOMAIN_CONFIG" ]] || { echo "Missing $DOMAIN_CONFIG" >&2; exit 1; }

DOMAINS=$(grep -v '^\s*#' "$DOMAIN_CONFIG" | grep -v '^\s*$' | tr '\n' ' ' | xargs)
[[ -n "$DOMAINS" ]] || { echo "No domains in $DOMAIN_CONFIG" >&2; exit 1; }

mkdir -p "$WEBROOT" "$NGINX_SSL_BASE" /etc/letsencrypt/configs
log "Domains: $DOMAINS"

CMD=(certbot certonly --webroot -w "$WEBROOT" --cert-name "$CERT_NAME"
  --email "$PRIMARY_EMAIL" --agree-tos --non-interactive --expand)
for d in $DOMAINS; do CMD+=(-d "$d"); done

log "Running: ${CMD[*]}"
"${CMD[@]}" >>"$LOG_FILE" 2>&1

[[ -d "$LE_LIVE_PATH" ]] || { echo "Cert path missing: $LE_LIVE_PATH" >&2; exit 1; }

ln -sf "$LE_LIVE_PATH/fullchain.pem" "$NGINX_SSL_BASE/fullchain.crt"
ln -sf "$LE_LIVE_PATH/privkey.pem"   "$NGINX_SSL_BASE/private.key"
ln -sf "$LE_LIVE_PATH/chain.pem"     "$NGINX_SSL_BASE/chain.crt"
ln -sf "$LE_LIVE_PATH/cert.pem"      "$NGINX_SSL_BASE/cert.crt"

nginx -t >>"$LOG_FILE" 2>&1
systemctl reload nginx >>"$LOG_FILE" 2>&1
certbot certificates --cert-name "$CERT_NAME" | tee -a "$LOG_FILE"
log "Certificate ready at $NGINX_SSL_BASE"
