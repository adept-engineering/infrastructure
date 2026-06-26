# Network Binding (0.0.0.0)

## What changed

All user-facing services listen on **all interfaces** (`0.0.0.0`), not just localhost.

| Service | Config file | Setting |
|---------|-------------|---------|
| HTTP proxy (8090) | `~/workspace/kasm/nginx/http-proxy.conf` | `listen 0.0.0.0:8090;` |
| Kasm HTTPS (9443) | `/opt/kasm/1.17.0/conf/nginx/orchestrator.conf` | `listen 0.0.0.0:9443 ssl;` |
| Session ports (agent) | `/opt/kasm/1.17.0/conf/app/agent/agent.app.config.yaml` | `docker_port_listen_addr: 0.0.0.0` |

## Verify

```bash
ss -tlnp | grep -E '8090|9443'
# expect 0.0.0.0:8090 and 0.0.0.0:9443

curl -s -o /dev/null -w '%{http_code}\n' http://10.0.5.36:8090/
```

## After editing Kasm configs

```bash
sudo /opt/kasm/bin/restart proxy
sudo /opt/kasm/bin/restart kasm_agent
cd ~/workspace/kasm && docker compose -f docker-compose.http.yml up -d --force-recreate
```

## OCI / firewall

Binding `0.0.0.0` alone is not enough — ensure OCI NSG allows **8090** and **9443** from your VCN CIDR (`10.0.0.0/16`).

## Why agent `docker_port_listen_addr` matters

Default `localhost` only publishes session container ports on 127.0.0.1. Setting `0.0.0.0` allows the Kasm proxy to reach session VNC/WebSocket ports correctly when clients connect from remote hosts.
