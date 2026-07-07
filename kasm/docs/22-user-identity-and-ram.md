# User identity and per-user RAM

## RAM: what you actually get

`free -h` inside a session shows the **host’s total RAM** (~31 GiB on Desktop-server). That is misleading.

Your real limit is the **Docker cgroup** for your workspace tier:

```bash
# Your allocation (bytes; 2147483648 = 2 GiB, 17179869184 = 16 GiB)
cat /sys/fs/cgroup/memory.max 2>/dev/null || cat /sys/fs/cgroup/memory/memory.limit_in_bytes

# Kasm workspace memory from DB (MiB)
# Admin or: see your tile name — Ubuntu Jammy (2 GB) vs (16 GB)
```

| What you see | Meaning |
|--------------|---------|
| `free` total ~31 GiB | Whole server — **not** your quota |
| `memory.max` ~2 GiB | **2 GB tier** (default users) |
| `memory.max` ~16 GiB | **16 GB tier** (e.g. remikuti) |

You only get the RAM for your tier. Using more than that can trigger OOM (session killed). You do **not** get the full 31 GiB unless you are on the 16 GB tier and that tier is what was launched.

---

## 1) Terminal / whoami

**Expected Kasm behavior:** the Linux account inside the container is always created as `kasm-user`. Your **Kasm login** (e.g. `remikuti` or `name@adeptengr.com`) is separate.

**What we configured:**

```bash
~/workspace/kasm/scripts/apply-user-identity.sh
```

This enables `expose_user_environment_vars` and on session start:

1. Renames the Linux user from `KASM_USER` (`whoami` matches your login)
2. Sets home to `/home/<username>` (not `/home/kasm-user`)
3. Kasm still syncs profiles via `/home/kasm-user` internally; your session uses `/home/<username>`

| Kasm username | Terminal `whoami` | Home directory |
|---------------|-------------------|----------------|
| `remikuti` | `remikuti` | `/home/remikuti` |
| `great.abiegbe@adeptengr.com` | `great.abiegbe_adeptengr.com` | `/home/great.abiegbe_adeptengr.com` |

**Tip:** use short POSIX usernames (`remikuti`) in the admin UI if you want clean terminal and path names.

Users must **end the session and start a new one** after this is applied.

---

## 2) Different RAM per user (e.g. Remi 16 GB, others 2 GB)

Kasm sets RAM **per workspace definition**, not per user. Adept uses **tier workspaces + groups**:

| Config (`config/user-resources.env`) | Workspace tile | Group |
|--------------------------------------|----------------|-------|
| `remikuti=16384` | Ubuntu Jammy (16 GB) | Adept RAM 16 GB |
| `*=2048` | Ubuntu Jammy (2 GB) | Adept RAM 2 GB |

Apply:

```bash
~/workspace/kasm/scripts/apply-user-resources.sh
```

Edit `config/user-resources.env`, then re-run the script when allocations change.

**Notes:**

- The generic **Ubuntu Jammy** tile is hidden; users launch their sized tile.
- `resource-governor.sh` does **not** override tier workspaces (`(16 GB)` / `(2 MB)` names).
- **16 GB + several 2 GB sessions** needs enough host RAM (31 GiB host cannot run 16+2+2+2 concurrently — plan capacity).
- New session required after tier change.

---

## Admin UI equivalent

**Identity:** Groups → All Users → add setting `expose_user_environment_vars = True`.

**RAM:** Workspaces → duplicate Ubuntu Jammy with different Memory (MB) → Groups → assign users to groups that only see the right workspace.
