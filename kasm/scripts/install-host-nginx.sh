#!/usr/bin/env bash
# Install host nginx + certbot, deploy workspaces.adeptengr.com site, issue LE cert, tune Kasm.
set -euo pipefail

ADEPT_ROOT="/home/ubuntu/workspace/kasm"
DOMAIN="workspaces.adeptengr.com"

log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

[[ $EUID -eq 0 ]] || { echo "Run: sudo $0" >&2; exit 1; }

log "Installing nginx and certbot"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq nginx certbot python3-certbot-nginx

log "Deploying Let's Encrypt config"
mkdir -p /etc/letsencrypt/configs /var/www/certbot/workspaces.adeptengr.com /etc/nginx/ssl/workspaces.adeptengr.com
cp "${ADEPT_ROOT}/letsencrypt/workspaces-domains.conf" /etc/letsencrypt/configs/workspaces-domains.conf
cp "${ADEPT_ROOT}/letsencrypt/workspaces-email.conf"   /etc/letsencrypt/configs/workspaces-email.conf
chmod 640 /etc/letsencrypt/configs/workspaces-email.conf

log "Deploying HTTP-only site for ACME (temporary if no cert yet)"
cp "${ADEPT_ROOT}/nginx/workspaces-http-bootstrap.conf" /etc/nginx/sites-available/workspaces.adeptengr.com
ln -sf /etc/nginx/sites-available/workspaces.adeptengr.com /etc/nginx/sites-enabled/workspaces.adeptengr.com
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl enable nginx && systemctl restart nginx

log "Issuing certificate"
cp "${ADEPT_ROOT}/scripts/generate-workspaces-certs.sh" /usr/local/bin/generate-workspaces-certs.sh
cp "${ADEPT_ROOT}/scripts/renew-workspaces-certs.sh"   /usr/local/bin/renew-workspaces-certs.sh
chmod +x /usr/local/bin/generate-workspaces-certs.sh /usr/local/bin/renew-workspaces-certs.sh
/usr/local/bin/generate-workspaces-certs.sh

log "Deploying full HTTPS site"
cp "${ADEPT_ROOT}/nginx/workspaces.adeptengr.com.conf" /etc/nginx/sites-available/workspaces.adeptengr.com

log "Stopping Docker HTTP proxy on :8090 (host nginx owns 80/443/8090)"
if command -v docker >/dev/null; then
  docker compose -f "${ADEPT_ROOT}/docker-compose.http.yml" down 2>/dev/null || true
fi

nginx -t && systemctl restart nginx

log "Kasm zone + branding hostname -> ${DOMAIN}"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "UPDATE zones SET proxy_port = 443, proxy_hostname = '\$request_host\$' WHERE zone_name = 'default';"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "UPDATE branding_configs SET hostname = '${DOMAIN}' WHERE name = 'Adept';"

log "Opening firewall ports 80 and 443 (host iptables)"
iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || iptables -I INPUT 5 -p tcp --dport 80 -j ACCEPT || true
iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || iptables -I INPUT 6 -p tcp --dport 443 -j ACCEPT || true
if command -v netfilter-persistent >/dev/null; then
  netfilter-persistent save 2>/dev/null || true
fi

log "Done. Test: https://${DOMAIN}/"
log "Renewal cron: 50 2 * * * /usr/local/bin/renew-workspaces-certs.sh"
