# HTTP Proxy (Port 8090) — **Legacy**

> **Superseded by [19-https-domain.md](19-https-domain.md).** Production entry is `https://workspaces.adeptengr.com/` via host nginx. The Docker HTTP proxy below is kept for reference only.

Kasm serves HTTPS on 9443 with a **self-signed** certificate. Browsers show security warnings. Users on an internal VCN typically want plain HTTP without cert friction.

## Solution

Nginx reverse proxy on **8090** → `https://127.0.0.1:9443` with `proxy_ssl_verify off`.

Managed via compose in **our** workspace (not `/opt/kasm`):

```bash
cd ~/workspace/kasm
docker compose -f docker-compose.http.yml up -d
```

## Files

- `docker-compose.http.yml` — `adept-kasm-http` container, `network_mode: host`
- `nginx/http-proxy.conf` — upstream and WebSocket headers

## Why `network_mode: host`

Kasm proxy binds to host port 9443. Host networking avoids extra bridge NAT and keeps WebSocket upgrades simple.

## User URL

```
http://10.0.5.36:8090
```

## Verify

```bash
curl -s -o /dev/null -w 'HTTP 8090 -> %{http_code}\n' http://127.0.0.1:8090/
# expect 200
docker ps | grep adept-kasm-http
```

## Restart

```bash
cd ~/workspace/kasm
docker compose -f docker-compose.http.yml restart
```

## If 8090 returns 502/000

1. Check Kasm proxy: `curl -sk https://127.0.0.1:9443/` → should be 200
2. Start Kasm: `sudo /opt/kasm/bin/start`
3. Check nginx logs: `docker logs adept-kasm-http`

## Headers note

`proxy_set_header Host $host:$server_port` and `X-Forwarded-Proto http` are required for Kasm to generate correct session URLs behind the HTTP front door.

`proxy_hide_header Strict-Transport-Security` prevents the browser from upgrading to HTTPS and hitting cert warnings.
