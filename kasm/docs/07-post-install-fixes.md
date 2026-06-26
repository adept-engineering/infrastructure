# Post-Install Fixes

Learned from build-server PoC; applied on Desktop-server 2026-06-25.

## 6a. Session slot limit

**Symptom:** Second user gets "contact administrator" when opening a workspace.

**Cause:** Installer sets `max_simultaneous_sessions = 1`.

**Fix:**

```bash
docker exec kasm_db psql -U kasmapp -d kasm -c \
  "UPDATE servers SET max_simultaneous_sessions = 4;
   SELECT hostname, cores, max_simultaneous_sessions FROM servers;"
docker restart kasm_manager kasm_agent
```

CE license still caps ~5 total concurrent sessions.

## 6b. Ubuntu black screen (seccomp)

**Symptom:** Ubuntu Noble/Jammy session connects but shows black screen (no panel/icons).

**Cause:** Docker 28+ default seccomp breaks XFCE in Kasm desktop images.

**Fix:**

```bash
docker exec kasm_db psql -U kasmapp -d kasm -c "
UPDATE images SET run_config = '{\"hostname\": \"kasm\", \"security_opt\": [\"seccomp=unconfined\"]}'::jsonb
WHERE friendly_name IN ('Ubuntu Noble', 'Ubuntu Jammy');
"
```

**Important:** Users must **end old sessions** and launch **new** ones after this change.

## 6c. Lighter workspace images

**Why:** 31 GiB RAM shared across ~5 sessions — reduce per-session footprint.

```bash
docker exec kasm_db psql -U kasmapp -d kasm -c "
UPDATE images SET cores = 1, memory = 1610612736
WHERE friendly_name IN ('Ubuntu Noble', 'Ubuntu Jammy', 'Terminal');
"
```

1.5 GiB (1610612736 bytes) and 1 core per workspace.

## 6d. Disable webcam

Reduces startup noise and permission prompts:

```bash
docker exec kasm_db psql -U kasmapp -d kasm -c "
UPDATE group_settings SET value='False'
WHERE name='allow_kasm_webcam'
AND group_id IN (SELECT group_id FROM groups WHERE name='All Users');
"
```

## Apply order

Run DB updates → `docker restart kasm_manager kasm_agent` → have users start fresh sessions.
