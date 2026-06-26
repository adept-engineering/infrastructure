# Docker Storage — Critical Troubleshooting

## The problem we hit

Docker `data-root` was correctly set to `/data/docker`, but **containerd** (which stores image layers) defaulted to `/var/lib/containerd` on the **45 GB root disk**.

During `install.sh -W`, ~40 GB of workspace images filled root to **99%**:

```
write ... no space left on device
```

Docker images list showed 30 images (~42 GB) while `/data/docker` was only ~750 MB.

## Two different paths

| Path | What lives here |
|------|-----------------|
| `/data/docker` | Docker data-root: compose state, named volumes, network config |
| `/data/containerd` | Image layers, overlay snapshots (the big stuff) |
| ~~`/var/lib/containerd`~~ | **Old location — deleted after migration** |

**Do not assume** "everything Docker is in `/data/docker`." Image blobs are in containerd's root.

## Fix applied (2026-06-25)

1. Set containerd root in `/etc/containerd/config.toml`:
   ```toml
   root = "/data/containerd"
   state = "/run/containerd"
   ```
2. Migrated data: `rsync -a /var/lib/containerd/ /data/containerd/`
3. Stopped docker + containerd
4. Deleted old copy: `sudo rm -rf /var/lib/containerd`
5. Restarted services
6. Restarted Kasm: `sudo /opt/kasm/bin/start`

### Result

| Disk | Before | After |
|------|--------|-------|
| `/` | 99% (481 MB free) | 10% (~41 GB free) |
| `/data` | ~41 GB | ~43 GB |

## Verify storage config

```bash
sudo docker info | grep "Docker Root Dir"
grep '^root' /etc/containerd/config.toml
sudo du -sh /data/docker /data/containerd /var/lib/containerd
df -h / /data
```

Expected:
- Docker Root Dir: `/data/docker`
- containerd root: `/data/containerd`
- `/var/lib/containerd`: empty or ~4K placeholder

## If root fills again

```bash
docker system df
docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | sort -k2 -h
```

Remove unused workspace images you don't need:

```bash
docker rmi kasmweb/brave:1.17.0 kasmweb/chrome:1.17.0  # examples
```

**Never** delete `/data/containerd` while Docker is running.

## docker-compose vs containerd

`daemon.json` only moves Docker's metadata root. Containerd is configured separately. Both must point at `/data` on this host.
