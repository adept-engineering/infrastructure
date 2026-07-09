#!/usr/bin/env bash
# Patch sessions where identity or home path is still wrong. Runs every 2 min via governor.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

needs_patch() {
  local cname="$1"
  docker exec "$cname" bash -lc '
    u=$(whoami)
    h="${HOME:-}"
    p=$(getent passwd "$u" 2>/dev/null | cut -d: -f6)
    if [ "$u" = "kasm-user" ]; then exit 0; fi
    if [ "$h" = "/home/kasm-user" ]; then exit 0; fi
    if [ "$p" = "/home/kasm-user" ]; then exit 0; fi
    if [ ! -x /usr/local/sbin/adept-set-identity ]; then exit 0; fi
    exit 1
  ' 2>/dev/null
}

apply_patch() {
  local cname="$1" kasm_user
  kasm_user=$(docker exec "$cname" bash -lc 'echo -n "$KASM_USER"' 2>/dev/null || true)
  [[ -n "$kasm_user" ]] || return 0

  docker cp "${SCRIPT_DIR}/dev/adept-set-identity.sh" "${cname}:/tmp/adept-set-identity.sh" 2>/dev/null || return 0
  docker exec -u root -e KASM_USER="$kasm_user" "$cname" bash -c \
    'install -d /usr/local/sbin /etc/profile.d
     install -m 755 /tmp/adept-set-identity.sh /usr/local/sbin/adept-set-identity
     grep -q "/usr/local/sbin/adept-set-identity" /etc/sudoers 2>/dev/null || echo "kasm-user ALL=(ALL) NOPASSWD: /usr/local/sbin/adept-set-identity" >> /etc/sudoers
     export KASM_USER="'"${kasm_user}"'"
     /usr/local/sbin/adept-set-identity' 2>/dev/null || return 0

  local who home
  who=$(docker exec "$cname" bash -lc 'whoami' 2>/dev/null || true)
  home=$(docker exec "$cname" bash -lc 'getent passwd "$(whoami)" | cut -d: -f6' 2>/dev/null || true)
  adept_log "patched ${cname} -> ${who} home=${home}"
}

while read -r cname; do
  [[ -n "$cname" ]] || continue
  if needs_patch "$cname"; then
    apply_patch "$cname"
  fi
done < <(docker ps --format '{{.Names}}' | grep -vE '^kasm_' || true)
