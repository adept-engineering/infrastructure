#!/usr/bin/env python3
"""Provision single admin-gated Adept Dev workspace (16 GB, full tool stack)."""
from __future__ import annotations

import subprocess
import sys
import uuid
from pathlib import Path

GROUP_NAME = "Adept Dev"
GROUP_PRIORITY = 45
WORKSPACE_NAME = "Adept Dev"
BASE_IMAGE = "Ubuntu Jammy (16 GB)"
FALLBACK_BASE = "Ubuntu Jammy"
DEV_MEM_MIB = 16384
PROFILE_PATH = "/data/adept/kasm/profiles/{username}/adept-dev"

# Legacy multi-tile names removed on provision
LEGACY_NAMES = (
    "Adept Dev — Base Desktop",
    "Adept Dev — Claude Code",
    "Adept Dev — Cursor",
    "Adept Dev — Antigravity",
    "Adept Dev — Devin",
)


def psql(sql: str) -> None:
    proc = subprocess.run(
        ["docker", "exec", "-i", "kasm_db", "psql", "-U", "kasmapp", "-d", "kasm", "-v", "ON_ERROR_STOP=1", "-q"],
        input=sql,
        text=True,
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit(proc.returncode)


def psql_scalar(sql: str) -> str:
    return subprocess.check_output(
        ["docker", "exec", "kasm_db", "psql", "-U", "kasmapp", "-d", "kasm", "-tAc", sql],
        text=True,
    ).strip()


def exec_config_json() -> str:
    script = Path(__file__).resolve().parent / "adept_exec_config.py"
    out = subprocess.check_output([sys.executable, str(script), "adept-dev"], text=True)
    return out.replace("'", "''")


def main() -> None:
    base_id = psql_scalar(f"SELECT image_id FROM images WHERE friendly_name = '{BASE_IMAGE}' LIMIT 1;")
    if not base_id:
        base_id = psql_scalar(f"SELECT image_id FROM images WHERE friendly_name = '{FALLBACK_BASE}' LIMIT 1;")
    if not base_id:
        raise SystemExit(f"Base image missing: {BASE_IMAGE} or {FALLBACK_BASE}")

    grp_id = psql_scalar(f"SELECT group_id FROM groups WHERE name = '{GROUP_NAME}' LIMIT 1;")
    img_id = str(uuid.uuid4())
    mem_bytes = DEV_MEM_MIB * 1024 * 1024
    exec_cfg = exec_config_json()
    parts = ["BEGIN;"]

    if not grp_id:
        grp_id = str(uuid.uuid4())
        parts.append(
            f"INSERT INTO groups (group_id, name, priority, is_system) VALUES ('{grp_id}', '{GROUP_NAME}', {GROUP_PRIORITY}, false);"
        )

    for name in LEGACY_NAMES:
        parts.append(
            f"DELETE FROM group_images WHERE image_id IN (SELECT image_id FROM images WHERE friendly_name = '{name}');"
        )
        parts.append(f"DELETE FROM images WHERE friendly_name = '{name}';")

    parts.append(
        f"DELETE FROM group_images WHERE image_id IN (SELECT image_id FROM images WHERE friendly_name = '{WORKSPACE_NAME}');"
    )
    parts.append(f"DELETE FROM images WHERE friendly_name = '{WORKSPACE_NAME}';")

    parts.append(
        f"""
INSERT INTO images (
  image_id, cores, description, docker_registry, docker_token, docker_user,
  image_src, enabled, available, friendly_name, memory, name, run_config,
  volume_mappings, restrict_network_names, exec_config, categories,
  require_gpu, gpu_count, hidden, image_type, cpu_allocation_method,
  uncompressed_size_mb, launch_config, is_remote_app, session_banner_force_disabled,
  filter_policy_force_disabled, override_egress_gateways, allow_network_selection,
  persistent_profile_path
)
SELECT
  '{img_id}', 4,
  'Admin-gated 16 GB dev desktop: Cursor, Claude Code, Antigravity, Devin',
  docker_registry, docker_token, docker_user,
  image_src, true, true, '{WORKSPACE_NAME}', {mem_bytes}, name, run_config,
  volume_mappings, restrict_network_names, '{exec_cfg}'::json, categories,
  require_gpu, gpu_count, false, image_type, cpu_allocation_method,
  uncompressed_size_mb, launch_config, is_remote_app, session_banner_force_disabled,
  filter_policy_force_disabled, override_egress_gateways, allow_network_selection,
  '{PROFILE_PATH}'
FROM images WHERE image_id = '{base_id}';
"""
    )
    parts.append(
        f"DELETE FROM group_images WHERE group_id = '{grp_id}' AND image_id IN (SELECT image_id FROM images WHERE friendly_name LIKE 'Adept Dev%');"
    )
    parts.append(
        f"INSERT INTO group_images (group_image_id, group_id, image_id) VALUES (uuid_generate_v4(), '{grp_id}', '{img_id}');"
    )

    parts.append("COMMIT;")
    psql("\n".join(parts))
    print(f"Provisioned '{WORKSPACE_NAME}' in group '{GROUP_NAME}' ({DEV_MEM_MIB} MiB)")
    print("Grant access: ./scripts/grant-dev-access.sh <username>  or  ./scripts/sync-dev-access.sh")


if __name__ == "__main__":
    main()
