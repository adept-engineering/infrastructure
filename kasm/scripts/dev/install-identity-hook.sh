#!/usr/bin/env bash
# Install login-time identity hook (profile.d + sbin script). Run as root.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -d /usr/local/sbin
install -m 0755 "${SRC_DIR}/adept-set-identity.sh" /usr/local/sbin/adept-set-identity

cat >/etc/profile.d/adept-identity.sh <<'EOF'
# Adept: align Linux user + HOME with Kasm login
if [ -n "${KASM_USER:-}" ]; then
  case "$(id -un)" in
    kasm-user|*)
      if [ "$HOME" = "/home/kasm-user" ] || [ "$(id -un)" = "kasm-user" ]; then
        sudo -n /usr/local/sbin/adept-set-identity 2>/dev/null || true
        # shellcheck source=/dev/null
        [ -f /etc/profile.d/adept-home.sh ] && . /etc/profile.d/adept-home.sh
      fi
      ;;
  esac
fi
EOF
chmod 644 /etc/profile.d/adept-identity.sh

/usr/local/sbin/adept-set-identity || true
