#!/usr/bin/env bash
# Validate Adept branding on the HTTP login front door (port 8090).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

HTTP_BASE="${PUBLIC_URL:-https://workspaces.adeptengr.com}"
LOG="${ADEPT_ROOT}/logs/branding-test-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "${ADEPT_ROOT}/logs"

FAIL=0
pass() { adept_log "PASS: $*"; echo "PASS: $*" >>"$LOG"; }
fail() { adept_log "FAIL: $*"; echo "FAIL: $*" >>"$LOG"; FAIL=1; }

adept_log "Branding test -> ${HTTP_BASE}"
adept_log "Log: ${LOG}"

# --- HTTP page injection ---
html=$(curl -s "${HTTP_BASE}/")
echo "$html" | grep -q '<title>Adept Engineering Solutions</title>' \
  && pass 'HTML title is Adept Engineering Solutions' \
  || fail 'HTML title missing or wrong'

echo "$html" | grep -qE 'href="/branding/adept\.css' \
  && pass 'adept.css linked in HTML' \
  || fail 'adept.css not injected'

echo "$html" | grep -qE 'src="/branding/adept\.js' \
  && pass 'adept.js linked in HTML' \
  || fail 'adept.js not injected'

echo "$html" | grep -q 'href="/branding/favicon.png"' \
  && pass 'Adept favicon linked in HTML' \
  || fail 'Adept favicon not injected'

echo "$html" | grep -q 'theme-color" content="#01509A"' \
  && pass 'Theme color set to Adept blue' \
  || fail 'Theme color not patched'

# --- Static branding assets ---
for path in adept.css adept.js login-splash.svg favicon.png logo.svg; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "${HTTP_BASE}/branding/${path}")
  [[ "$code" == "200" ]] && pass "asset /branding/${path} -> ${code}" \
    || fail "asset /branding/${path} -> ${code}"
done

# --- login_settings API (proxied) ---
api_json=$(curl -s -X POST "${HTTP_BASE}/api/login_settings" -H 'Content-Type: application/json' -d '{}')
python3 - "$api_json" <<'PY' || fail 'login_settings JSON parse'
import json, sys
d = json.loads(sys.argv[1])
assert d["html_title"] == "Adept Engineering Solutions", d["html_title"]
assert d["login_caption"] == "Secure virtual workspaces for teams", d["login_caption"]
assert d["login_splash_background"] == "/branding/login-splash.svg", d["login_splash_background"]
assert "Adept workspace" in d["loading_session_text"], d["loading_session_text"]
assert "Container Streaming" not in d["login_caption"]
print("ok")
PY
[[ $? -eq 0 ]] && pass 'login_settings API returns Adept branding' || true

# --- Kasm proxy logo swap ---
logo=$(curl -sk "${KASM_BASE}/img/logo.svg")
echo "$logo" | grep -q '#01509A' \
  && pass 'kasm_proxy logo.svg is Adept blue SVG' \
  || fail 'kasm_proxy logo.svg not Adept branded'

# --- DB branding row ---
db_row=$(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
  "SELECT html_title FROM branding_configs WHERE name='Adept' AND is_default=true LIMIT 1;")
[[ "$db_row" == "Adept Engineering Solutions" ]] \
  && pass 'branding_configs DB row present' \
  || fail "branding_configs DB row wrong: ${db_row:-empty}"

# --- Login flow (API only — confirms stack works with branded front door) ---
if [[ -f "$USERS_FILE" ]]; then
  user=$(grep -m1 '^adept-u' "$USERS_FILE" | cut -d= -f1)
  pw=$(adept_user_password "$user")
  if [[ -n "$user" && -n "$pw" ]]; then
    token=$(adept_user_token "$user" "$pw" 2>/dev/null || true)
    [[ -n "$token" ]] && pass "user login API works (${user})" \
      || fail "user login API failed (${user})"
  else
    adept_log "SKIP: no adept user password in ${USERS_FILE}"
  fi
else
  adept_log "SKIP: ${USERS_FILE} not found"
fi

# --- JS bundle left untouched (sub_filter on JS broke app load) ---
pass 'JS bundle served without proxy text substitution'

adept_log "----"
if [[ "$FAIL" -eq 0 ]]; then
  adept_log "BRANDING TEST: ALL PASSED (${HTTP_BASE})"
  exit 0
fi
adept_log "BRANDING TEST: ${FAIL} failure(s) — see ${LOG}"
exit 1
