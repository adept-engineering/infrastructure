# HTTPS Domain — workspaces.adeptengr.com

## Why this fixes the Play button

Kasm's web UI **hardcodes `https://`** for VNC/stream URLs. On plain HTTP `:8090`, the browser tried `https://localhost:8090/...` and failed silently.

Serving the site at **`https://workspaces.adeptengr.com`** (port 443) aligns with Kasm's expectations — no bundle patching required.

## Topology (single host)

```
Internet
   │
   ▼ :80 / :443
Host nginx (Let's Encrypt TLS)
   │
   ▼ https://127.0.0.1:9443
Kasm proxy (Docker)
   │
   ▼
Session containers (VNC/WebSocket)
```

| Public URL | Purpose |
|------------|---------|
| `https://workspaces.adeptengr.com/` | User + admin login |
| `http://workspaces.adeptengr.com:8090/` | Redirect → HTTPS (legacy bookmarks) |
| `https://10.0.5.36:9443` | Internal Kasm only (self-signed) |

## Files

| Path | Role |
|------|------|
| `nginx/workspaces.adeptengr.com.conf` | Host nginx site (TLS + branding) |
| `letsencrypt/workspaces-domains.conf` | Cert SAN list |
| `letsencrypt/workspaces-email.conf` | ACME contact email |
| `scripts/install-host-nginx.sh` | One-shot install |
| `scripts/generate-workspaces-certs.sh` | Issue / expand cert |
| `scripts/renew-workspaces-certs.sh` | Daily renewal |

Cert name: `adept-workspaces-unified`  
Symlinks: `/etc/nginx/ssl/workspaces.adeptengr.com/`

## Install (already done on Desktop-server)

```bash
sudo ~/workspace/kasm/scripts/install-host-nginx.sh
```

## Firewall (required)

**Host iptables** — ports 80 and 443 must be allowed **before** the default REJECT rule:

```bash
sudo iptables -I INPUT 5 -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT 6 -p tcp --dport 443 -j ACCEPT
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

**OCI NSG** — add stateful ingress from `0.0.0.0/0` (or your CIDR) for TCP **80** and **443** on this instance's VNIC.

## Renewal cron

```cron
50 2 * * * /usr/local/bin/renew-workspaces-certs.sh
```

## Kasm zone settings

```sql
UPDATE zones SET proxy_port = 443, proxy_hostname = '$request_host$' WHERE zone_name = 'default';
```

`start-all.sh` enforces this on every boot.

## User access

- **URL:** https://workspaces.adeptengr.com/
- **Admin:** `great.abiegbe@adeptengr.com` (create users under ADMIN → Access Management → Users)
- **CE has no public signup** — admin must provision accounts

## Verify

```bash
curl -sI https://workspaces.adeptengr.com/
sudo certbot certificates --cert-name adept-workspaces-unified
source ~/workspace/kasm/.env && ~/workspace/kasm/scripts/healthcheck.sh
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| ACME fails | Open port 80 on iptables + OCI NSG; confirm DNS → server public IP |
| `443 connection refused` | `sudo nginx -t`; ensure Docker proxy on 8090 is stopped before nginx binds 8090 redirect |
| Play → 100% → dashboard | Destroy stale sessions; confirm zone `proxy_port=443`; use HTTPS URL only |
| Branding missing | `~/workspace/kasm/scripts/apply-branding.sh` |
