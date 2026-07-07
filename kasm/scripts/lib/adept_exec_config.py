#!/usr/bin/env python3
"""Build Kasm exec_config: identity hooks + optional Adept Dev toolchain bootstrap."""
from __future__ import annotations

import json
import sys
from pathlib import Path

DEV_DIR = Path(__file__).resolve().parent.parent / "dev"

INSTALL_IDENTITY_HOOK = (DEV_DIR / "install-identity-hook.sh").read_text()
INSTALL_STACK = (DEV_DIR / "install-adept-stack.sh").read_text()

IDENTITY_RUN = r"""
for _ in $(seq 1 45); do
  [ -n "${KASM_USER:-}" ] && break
  KASM_USER=$(tr '\0' '\n' < /proc/1/environ 2>/dev/null | sed -n 's/^KASM_USER=//p' | head -1)
  [ -n "${KASM_USER:-}" ] && export KASM_USER && break
  sleep 1
done
/usr/local/sbin/adept-set-identity 2>/dev/null || true
"""


def _bash_cmd(body: str) -> str:
    return "bash -c " + json.dumps(body)


def _identity_hook_body() -> str:
    return INSTALL_IDENTITY_HOOK + "\n" + IDENTITY_RUN.strip()


def build(install_key: str = "base") -> dict:
    identity_hook = {"user": "root", "cmd": _bash_cmd(_identity_hook_body())}
    if install_key != "adept-dev":
        return {"first_launch": identity_hook, "go": identity_hook, "assign": identity_hook}
    first_hook = {"user": "root", "cmd": _bash_cmd(_identity_hook_body() + "\n" + INSTALL_STACK)}
    return {"first_launch": first_hook, "go": identity_hook, "assign": identity_hook}


if __name__ == "__main__":
    key = sys.argv[1] if len(sys.argv) > 1 else "base"
    print(json.dumps(build(key)))
