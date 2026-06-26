# Architecture

## Goal

Browser-based isolated virtual desktops (AWS Workspaces–style) for ~5 Adept users. Each user gets their own containerized desktop; one user rebooting does not affect others.

## Why Kasm (not raw Docker Compose for desktops)

| Approach | Problem |
|----------|---------|
| 5 static `docker-compose` desktop services | No session broker, no browser streaming, fixed mapping user→container |
| Apache Guacamole | RDP/VNC gateway only — no orchestration or isolation |
| **Kasm Workspaces CE** | Built for this: spawns per-session containers, streams to browser, admin UI |

Kasm **uses** Docker Compose for the **platform**, but **user sessions** are dynamic containers created by `kasm_agent`.

## Component map

```
Browser (user)
    │
    ▼
adept-kasm-http (nginx, port 8090)     ← ~/workspace/kasm/docker-compose.http.yml
    │  proxy_pass → https://127.0.0.1:9443
    ▼
kasm_proxy (port 9443)                   ← /opt/kasm/current/docker/
    │
    ├── kasm_api / kasm_manager / kasm_db / kasm_redis
    └── kasm_agent ──► spawns userkasm.loc_* per session
                              │
                              ├── Ubuntu Noble (desktop)
                              ├── VS Code
                              └── Terminal
```

## Directory layout (do not confuse)

| Path | Owner | Purpose |
|------|-------|---------|
| `/opt/kasm/` | `kasm` user | Platform install (installer output) |
| `~/workspace/kasm/` | `ubuntu` | Our config: HTTP proxy, docs, `.env` |
| `/data/adept/kasm/profiles/` | `ubuntu` | Persistent user home directories |
| `/data/docker` | docker | Docker metadata, volumes |
| `/data/containerd` | root | Image layers (~40 GB) |

## Session isolation

- Each launch creates a new `userkasm.loc_<id>` container.
- Containers share nothing except host kernel and Docker network.
- **Persistent Profile** mounts `/data/adept/kasm/profiles/{username}` so user data survives session end.
- CE license caps **~5 concurrent sessions** total on this host.

## Limits on Desktop-server

| Limit | Value |
|-------|-------|
| CE concurrent sessions | ~5 |
| `max_simultaneous_sessions` (server) | 4 (DB setting; headroom for system) |
| Per-user workspaces | 5 (`max_kasms_per_user` in All Users group) |
| Ubuntu/Terminal RAM per session | 1.5 GiB (tuned down from default) |
