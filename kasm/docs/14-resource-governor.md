# Dynamic Resource Governor

## Problem

Desktop-server has **31 GiB RAM** shared by 4–5 users. Fixed 1.5 GiB per session wastes RAM when only 3 people are working; too little RAM when everyone runs heavy workloads.

## Solution

`scripts/resource-governor.sh` recalculates per-image **memory** and **CPU** in the Kasm database based on:

1. Total system RAM (`/proc/meminfo`)
2. Platform reserve (6 GiB for OS + Kasm services)
3. Active + planned session slots (up to `ADEPT_MAX_SESSIONS=5`)

## Formula

```
allocable = total_ram - platform_reserve
per_session = allocable / max(ADEPT_MAX_SESSIONS - active_sessions, 1)
per_session = clamp(per_session, MIN=1536 MiB, MAX=10240 MiB)
```

| Active sessions | Typical Ubuntu desktop RAM | Cores (desktop) |
|-----------------|---------------------------|-----------------|
| 0 (planning) | ~5 GiB | 1 |
| 5 | ~4–5 GiB | 1 |
| 3 | ~7–8 GiB | 2 |
| 1 | up to 10 GiB cap | 2 |

## When it runs

```bash
# Manual
~/workspace/kasm/scripts/resource-governor.sh

# Cron (every 2 minutes)
~/workspace/kasm/scripts/install-cron.sh
```

Also runs from `start-all.sh` on boot.

## Important

- **New sessions only** — a running desktop does not resize until the user ends and relaunches.
- After governor changes, tell users to restart workspaces if they need more RAM mid-session.
- Tune `config/adept.defaults.env` for your host.

## Verify

```bash
~/workspace/kasm/scripts/resource-governor.sh --dry-run
docker exec kasm_db psql -U kasmapp -d kasm -c \
  "SELECT friendly_name, (memory/1024/1024)::int AS mib, cores FROM images WHERE friendly_name LIKE 'Ubuntu%';"
```
