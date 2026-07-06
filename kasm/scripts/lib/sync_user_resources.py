#!/usr/bin/env python3
"""Sync per-user RAM tiers: clone workspaces + Kasm groups from user-resources.env."""
from __future__ import annotations

import subprocess
import sys
import uuid
from pathlib import Path

BASE_IMAGE = "Ubuntu Jammy"


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


def load_config(path: Path) -> tuple[int, dict[int, list[str]]]:
    default_mib: int | None = None
    tiers: dict[int, list[str]] = {}
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line or "=" not in line:
            continue
        user, val = (p.strip() for p in line.split("=", 1))
        mib = int(val)
        if user == "*":
            default_mib = mib
        else:
            tiers.setdefault(mib, []).append(user)
    if default_mib is None:
        raise SystemExit("config must include *=<mib> default tier")
    return default_mib, tiers


def tier_label(mib: int) -> tuple[str, str]:
    if mib >= 1024 and mib % 1024 == 0:
        gb = mib // 1024
        return f"{gb} GB", f"{gb}gb"
    return f"{mib} MB", f"{mib}mb"


def main() -> None:
    cfg = Path(sys.argv[1])
    default_mib, tiers = load_config(cfg)

    base = subprocess.check_output(
        [
            "docker", "exec", "kasm_db", "psql", "-U", "kasmapp", "-d", "kasm", "-tAc",
            f"SELECT image_id FROM images WHERE friendly_name = '{BASE_IMAGE}' LIMIT 1;",
        ],
        text=True,
    ).strip()
    if not base:
        raise SystemExit(f"Base image not found: {BASE_IMAGE}")

    all_mibs = sorted(set(tiers) | {default_mib}, reverse=True)
    tier_group: dict[int, tuple[str, str]] = {}  # mib -> (group_id, image_id)

    sql_parts = [
        "BEGIN;",
        f"UPDATE images SET hidden = true WHERE friendly_name = '{BASE_IMAGE}' AND image_type = 'Container';",
    ]

    for mib in all_mibs:
        label, _slug = tier_label(mib)
        tier_name = f"Ubuntu Jammy ({label})"
        grp_name = f"Adept RAM {label}"
        grp_id = str(uuid.uuid4())
        img_id = str(uuid.uuid4())
        mem_bytes = mib * 1024 * 1024
        tier_group[mib] = (grp_id, img_id)

        sql_parts.append(f"DELETE FROM group_images WHERE image_id IN (SELECT image_id FROM images WHERE friendly_name = '{tier_name}');")
        sql_parts.append(f"DELETE FROM images WHERE friendly_name = '{tier_name}';")
        sql_parts.append(f"DELETE FROM user_groups WHERE group_id IN (SELECT group_id FROM groups WHERE name = '{grp_name}' AND COALESCE(is_system, false) = false);")
        sql_parts.append(f"DELETE FROM groups WHERE name = '{grp_name}' AND COALESCE(is_system, false) = false;")
        sql_parts.append(
            f"INSERT INTO groups (group_id, name, priority, is_system) VALUES ('{grp_id}', '{grp_name}', 50, false);"
        )
        sql_parts.append(f"""
INSERT INTO images (
  image_id, cores, description, docker_registry, docker_token, docker_user,
  image_src, enabled, available, friendly_name, memory, name, run_config,
  volume_mappings, restrict_network_names, exec_config, categories,
  require_gpu, gpu_count, hidden, image_type, cpu_allocation_method,
  uncompressed_size_mb, launch_config, is_remote_app, session_banner_force_disabled,
  filter_policy_force_disabled, override_egress_gateways, allow_network_selection
)
SELECT
  '{img_id}', cores, description, docker_registry, docker_token, docker_user,
  image_src, true, true, '{tier_name}', {mem_bytes}, name, run_config,
  volume_mappings, restrict_network_names, exec_config, categories,
  require_gpu, gpu_count, false, image_type, cpu_allocation_method,
  uncompressed_size_mb, launch_config, is_remote_app, session_banner_force_disabled,
  filter_policy_force_disabled, override_egress_gateways, allow_network_selection
FROM images WHERE image_id = '{base}';
""")
        sql_parts.append(
            f"INSERT INTO group_images (group_image_id, group_id, image_id) VALUES (uuid_generate_v4(), '{grp_id}', '{img_id}');"
        )

    # Map each user to their tier group (keep All Users + Administrators)
    user_tier: dict[str, int] = {}
    for mib, users in tiers.items():
        for u in users:
            user_tier[u] = mib
    all_users = subprocess.check_output(
        ["docker", "exec", "kasm_db", "psql", "-U", "kasmapp", "-d", "kasm", "-tAc", "SELECT username FROM users;"],
        text=True,
    ).splitlines()
    for username in all_users:
        username = username.strip()
        if not username:
            continue
        mib = user_tier.get(username, default_mib)
        grp_id = tier_group[mib][0]
        uid = subprocess.check_output(
            [
                "docker", "exec", "kasm_db", "psql", "-U", "kasmapp", "-d", "kasm", "-tAc",
                f"SELECT user_id FROM users WHERE username = '{username.replace(chr(39), chr(39)+chr(39))}';",
            ],
            text=True,
        ).strip()
        if not uid:
            continue
        sql_parts.append(
            f"DELETE FROM user_groups WHERE user_id = '{uid}' AND group_id IN (SELECT group_id FROM groups WHERE name LIKE 'Adept RAM %');"
        )
        sql_parts.append(
            f"INSERT INTO user_groups (user_group_id, user_id, group_id) VALUES (uuid_generate_v4(), '{uid}', '{grp_id}');"
        )

    sql_parts.append("COMMIT;")
    psql("\n".join(sql_parts))
    print(f"Synced tiers: {', '.join(tier_label(m)[0] for m in all_mibs)}")


if __name__ == "__main__":
    main()
