# Troubleshooting Quick Reference

## Symptom → Fix

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `no space left on device` during image pull | containerd on root disk | [04-docker-storage.md](04-docker-storage.md) |
| `open /var/lib/docker-plugins/rclone/config` | Missing rclone dirs | [02-preflight-and-layout.md](02-preflight-and-layout.md) |
| HTTP 8090 → 000 | HTTP proxy or Kasm down | `sudo /opt/kasm/bin/start` + `docker compose -f docker-compose.http.yml up -d` |
| HTTP 8090 → 502 | Kasm proxy not ready | Wait for `kasm_proxy` healthy; check 9443 |
| HTTPS cert warning on IP | No IP in SAN | [06-tls-certificates.md](06-tls-certificates.md) or use HTTP 8090 |
| "Contact administrator" on 2nd session | `max_simultaneous_sessions=1` | [07-post-install-fixes.md](07-post-install-fixes.md) §6a |
| Ubuntu black screen | seccomp | [07-post-install-fixes.md](07-post-install-fixes.md) §6b — new session required |
| `kasm_agent unhealthy` | Docker restart, disk full, socket issue | Check `docker logs kasm_agent`; verify `/var/run/docker.sock` |
| Session won't start | Missing image | `docker images \| grep kasmweb/ubuntu-noble` |
| Profile data lost | Persistent profile not enabled | [08-users-and-profiles.md](08-users-and-profiles.md) |
| Can't reach from other hosts | Firewall / NSG | [09-operations.md](09-operations.md) firewall section |

## Diagnostic one-liner

```bash
echo "=== Disk ===" && df -h / /data && \
echo "=== Storage ===" && sudo du -sh /data/docker /data/containerd /var/lib/containerd 2>/dev/null && \
echo "=== HTTP/HTTPS ===" && \
curl -s -o /dev/null -w '8090:%{http_code} ' http://127.0.0.1:8090/ && \
curl -sk -o /dev/null -w '9443:%{http_code}\n' https://127.0.0.1:9443/ && \
echo "=== Containers ===" && docker ps -a --format '{{.Names}} {{.Status}}' | grep -E 'kasm|adept'
```

## After host reboot

```bash
sudo systemctl start containerd docker
sudo /opt/kasm/bin/start
cd ~/workspace/kasm && docker compose -f docker-compose.http.yml up -d
```

Consider enabling `restart: unless-stopped` on `adept-kasm-http` (already set) and relying on Kasm compose `restart: always`.

## Install log

Full installer output (if needed):

```
/tmp/kasm_install.log
/tmp/kasm_release/kasm_install_*.log
```

## Get help

1. Check agent logs during session launch: `docker logs -f kasm_agent`
2. Check manager: `docker logs kasm_manager --tail 100`
3. Kasm docs: https://kasmweb.com/docs/latest/
