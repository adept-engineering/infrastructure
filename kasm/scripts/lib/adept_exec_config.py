#!/usr/bin/env python3
"""Build Kasm exec_config: identity hooks + optional Adept Dev toolchain bootstrap."""
from __future__ import annotations

import json
import sys
from pathlib import Path

DEV_DIR = Path(__file__).resolve().parent.parent / "dev"

ADEPT_SET_IDENTITY = (DEV_DIR / "adept-set-identity.sh").read_text()
INSTALL_STACK = (DEV_DIR / "install-adept-stack.sh").read_text()

PROFILE_D_IDENTITY = r"""cat >/etc/profile.d/adept-identity.sh <<'EOF'
# Adept: align Linux user + HOME with Kasm login on every shell
if [ -n "${KASM_USER:-}" ]; then
  if [ "$(id -un)" = "kasm-user" ] || [ "$HOME" = "/home/kasm-user" ]; then
    /usr/local/sbin/adept-set-identity 2>/dev/null || true
  fi
  [ -f /etc/profile.d/adept-home.sh ] && . /etc/profile.d/adept-home.sh
fi
EOF
chmod 644 /etc/profile.d/adept-identity.sh"""

# Apply identity in the background after the container is up — blocking exec_config
# causes 409 "container is restarting" on Terminal / VS Code.
# Logs go to /var/log/adept (not /tmp — some desktop images clear /tmp shortly after
# boot, which is why failures here used to vanish before anyone could see them).
IDENTITY_RUN = r"""
mkdir -p /var/log/adept
(
  echo "[adept-identity] run start $(date -Iseconds)"
  for _ in $(seq 1 30); do
    [ -n "${KASM_USER:-}" ] && break
    KASM_USER=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | sed -n 's/^KASM_USER=//p' | head -1)
    [ -n "${KASM_USER:-}" ] && export KASM_USER && break
    sleep 1
  done
  echo "[adept-identity] KASM_USER=${KASM_USER:-<empty>}"
  /usr/local/sbin/adept-set-identity || echo "[adept-identity] adept-set-identity exited non-zero"
) >>/var/log/adept/identity.log 2>&1 &
"""


def _bash_cmd(body: str) -> str:
    return "bash -c " + json.dumps(body)


def _install_identity_body() -> str:
    return f"""install -d /usr/local/sbin /etc/profile.d
cat >/usr/local/sbin/adept-set-identity <<'ADEPT_IDENTITY_EOF'
{ADEPT_SET_IDENTITY}ADEPT_IDENTITY_EOF
chmod 755 /usr/local/sbin/adept-set-identity
{PROFILE_D_IDENTITY}
{IDENTITY_RUN.strip()}
"""


def build(install_key: str = "base") -> dict:
    identity_hook = {"user": "root", "cmd": _bash_cmd(_install_identity_body())}
    if install_key != "adept-dev":
        return {"first_launch": identity_hook, "go": identity_hook, "assign": identity_hook}
    first_hook = {"user": "root", "cmd": _bash_cmd(_install_identity_body() + "\n" + INSTALL_STACK)}
    return {"first_launch": first_hook, "go": identity_hook, "assign": identity_hook}


if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else "base"
    print(json.dumps(build(key)))
