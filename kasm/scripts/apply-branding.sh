#!/usr/bin/env bash
# Apply Adept Engineering Solutions branding to Kasm CE (no branding license required).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADEPT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BRAND="${ADEPT_ROOT}/branding"
PUBLIC_HOST="${PUBLIC_HOST:-workspaces.adeptengr.com}"

TITLE="Adept Engineering Solutions"
CAPTION="Secure virtual workspaces for teams"
LOADING="Loading your Adept workspace…"

adept_log() { printf '[%s] %s\n' "$(date -Iseconds)" "$*"; }

if ! docker ps --format '{{.Names}}' | grep -qx kasm_proxy; then
  echo "kasm_proxy is not running" >&2
  exit 1
fi

adept_log "Copying logo assets into kasm_proxy"
for dest in logo.svg kasm_logo.svg headerlogo.svg; do
  docker cp "${BRAND}/logo.svg" "kasm_proxy:/srv/www/img/${dest}"
done
docker cp "${BRAND}/favicon.png" kasm_proxy:/srv/www/img/favicon.png
docker cp "${BRAND}/favicon.png" kasm_proxy:/srv/www/img/Icon_1024x1024.png
docker cp "${BRAND}/login-splash.svg" kasm_proxy:/srv/www/img/login_splash.svg

adept_log "Updating branding_configs in database"
docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c "DELETE FROM branding_configs WHERE name = 'Adept';"

docker exec kasm_db psql -U kasmapp -d kasm -v ON_ERROR_STOP=1 -c \
  "INSERT INTO branding_configs (
    name, favicon_logo_url, header_logo_url, html_title, login_caption,
    login_logo_url, login_splash_url, loading_session_text, joining_session_text,
    destroying_session_text, is_default, hostname, launcher_background_url
  ) VALUES (
    'Adept', 'img/favicon.png', 'img/logo.svg', '${TITLE}', '${CAPTION}',
    'img/logo.svg', 'img/login_splash.svg', '${LOADING}', 'Joining session…',
    'Ending session…', true, '${PUBLIC_HOST}', 'img/backgrounds/background1.jpg'
  );"

adept_log "Updating PWA manifest name"
docker exec kasm_proxy sed -i 's/"name": "Kasm Workspaces"/"name": "Adept Engineering Solutions"/' /srv/www/api/basemanifest/manifest.webmanifest 2>/dev/null || true

if systemctl is-active --quiet nginx; then
  adept_log "Reloading host nginx (branding sub_filter on HTTPS)"
  sudo nginx -t && sudo systemctl reload nginx
fi

adept_log "Branding applied — open https://${PUBLIC_HOST}/"
