# Preflight and Directory Layout

## What we checked (Step 0)

```bash
hostname -I | awk '{print $1}'   # → 10.0.5.36
nproc                             # → 16
free -h                           # → 31 GiB RAM, no swap
df -h / /data                     # → 45G root, 688G data disk
sudo docker info | grep "Docker Root Dir"  # → /data/docker
docker compose version            # → v5.2.0
groups ubuntu                     # includes docker
```

## Why these matter

- **No swap:** Kasm installer fails swap check without `-H` flag.
- **Docker on `/data`:** Root disk is only 45 GB — too small for images.
- **`ubuntu` in `docker` group:** Required to run compose without sudo for our HTTP proxy.

## Directories created

```bash
sudo mkdir -p /data/adept/kasm/profiles
sudo mkdir -p /data/docker-plugins/rclone/{config,cache}
sudo mkdir -p /var/lib/docker-plugins/rclone/{config,cache}
sudo mkdir -p ~/workspace/kasm/{data/profiles,nginx,docs}
sudo chown -R ubuntu:ubuntu /data/adept ~/workspace
```

### Why each path

| Path | Why |
|------|-----|
| `/data/adept/kasm/profiles` | Large persistent user data on 653G data disk |
| `/data/docker-plugins/rclone` | Docker root is `/data/docker`; rclone plugin expects plugin dir |
| `/var/lib/docker-plugins/rclone` | Kasm install also hardcodes this path — **both required** or install fails |
| `~/workspace/kasm` | Version-controlled config separate from `/opt/kasm` |

## rclone error if skipped

```
open /var/lib/docker-plugins/rclone/config: no such file or directory
```

Fix: create both plugin directory trees before `install.sh`.

## Repo layout in workspace

```
~/workspace/kasm/
├── docker-compose.http.yml   # HTTP front door
├── nginx/http-proxy.conf
├── env.template
├── .env                      # gitignored — real credentials
├── docs/                     # this documentation
└── data/profiles/.gitkeep
```
