# Kasm CE Install

## Version

Kasm Workspaces **CE 1.17.0** (`kasm_release_1.17.0.7f020d.tar.gz`)

## Why `install.sh` (not a hand-written compose file)

Kasm CE does not ship a drop-in `docker-compose.yml` for greenfield installs. The installer:

1. Copies platform files to `/opt/kasm/1.17.0/`
2. Generates TLS certificates
3. Seeds PostgreSQL with workspace definitions and hashed passwords
4. Injects secrets into compose via `yq`
5. Registers the agent with a manager token
6. Pulls platform + workspace images (`-W`)

**After install**, day-to-day control **is** Docker Compose:

```bash
sudo /opt/kasm/bin/start   # → docker compose up -d in /opt/kasm/current/docker
sudo /opt/kasm/bin/stop
sudo /opt/kasm/bin/restart
```

## Install command used

```bash
cd /tmp/kasm_release
SERVER_IP=$(hostname -I | awk '{print $1}')

sudo bash install.sh \
  -e \          # accept EULA
  -H \          # skip swap check (no swap on this host)
  -b \          # skip disk check if installer complains
  -L 9443 \     # HTTPS listen port
  -p "$SERVER_IP" \
  -P '<admin-password>' \
  -U '<user-password>' \
  -W            # download default workspace images
```

### Flags we avoided

- **`-V noninteractive`** — failed on build-server PoC; do not use.

## Install duration

~8–15 minutes for platform; additional time for `-W` image pulls (~40+ GB).

## Install outcome on Desktop-server

- Platform containers: **success** — all `kasm_*` services healthy
- Workspace image pull: **partial failure** — root disk filled (see [04-docker-storage.md](04-docker-storage.md))
- Required images present: `ubuntu-noble-desktop`, `ubuntu-jammy-desktop`, `vs-code`, `terminal`

## Credentials location

Install prints admin/user passwords and DB/Redis/manager token. Ours are saved in:

```
~/workspace/kasm/.env
```

## Verify after install

```bash
curl -sk -o /dev/null -w '%{http_code}\n' https://127.0.0.1:9443/   # expect 200
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep kasm
```

## Platform compose file

Generated at `/opt/kasm/1.17.0/docker/docker-compose.yaml` — do not relocate; paths are baked in.

Services: `kasm_db`, `kasm_redis`, `kasm_api`, `kasm_manager`, `kasm_agent`, `kasm_proxy`, `kasm_guac`, `kasm_share`, `rdp_gateway`, `kasm_rdp_https_gateway`.
