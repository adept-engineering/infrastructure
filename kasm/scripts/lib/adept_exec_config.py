#!/usr/bin/env python3
"""Build Kasm exec_config: identity hooks + optional Adept Dev toolchain bootstrap."""
from __future__ import annotations

import json
import sys
from pathlib import Path

IDENTITY_BODY = r"""set -e
grep -q "kasm-user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null || echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers"
if [ -n "${KASM_USER:-}" ]; then
  u=$(echo "$KASM_USER" | sed -r "s#[^a-zA-Z0-9._-]#_#g" | cut -c1-32)
  if [ -n "$u" ] && [ "$u" != "kasm-user" ]; then
    if id kasm-user >/dev/null 2>&1; then
      usermod -l "$u" kasm-user 2>/dev/null || sed -i "s/^kasm-user:/${u}:/" /etc/passwd
      getent group kasm-user >/dev/null 2>&1 && groupmod -n "$u" kasm-user 2>/dev/null || true
    fi
  fi
fi"""

INSTALL_SCRIPT = Path(__file__).resolve().parent.parent / "dev" / "install-adept-stack.sh"


def _bash_cmd(body: str) -> str:
    return "bash -c " + json.dumps(body)


def _adept_dev_install_body() -> str:
    return INSTALL_SCRIPT.read_text()


def build(install_key: str = "base") -> dict:
    identity_hook = {"user": "root", "cmd": _bash_cmd(IDENTITY_BODY)}
    if install_key != "adept-dev":
        return {"first_launch": identity_hook, "go": identity_hook, "assign": identity_hook}
    first_body = IDENTITY_BODY + "\n" + _adept_dev_install_body()
    first_hook = {"user": "root", "cmd": _bash_cmd(first_body)}
    return {"first_launch": first_hook, "go": identity_hook, "assign": identity_hook}


if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else "base"
    print(json.dumps(build(key)))
