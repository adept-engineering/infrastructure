# Operations

## Start / stop

### Kasm platform

```bash
sudo /opt/kasm/bin/start
sudo /opt/kasm/bin/stop
sudo /opt/kasm/bin/restart
sudo /opt/kasm/bin/restart kasm_agent   # single service
```

These run `docker compose` in `/opt/kasm/1.17.0/docker/`.

### HTTP proxy (workspace)

```bash
cd ~/workspace/kasm
docker compose -f docker-compose.http.yml up -d
docker compose -f docker-compose.http.yml down
docker compose -f docker-compose.http.yml restart
```

## Health checks

```bash
# Platform
curl -sk -o /dev/null -w 'HTTPS 9443 -> %{http_code}\n' https://127.0.0.1:9443/
curl -s -o /dev/null -w 'HTTP 8090 -> %{http_code}\n' http://127.0.0.1:8090/

# Containers
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep -E 'kasm|adept'

# Active user sessions
docker ps --format '{{.Names}}' | grep userkasm
```

## Logs

```bash
# Platform logs directory
sudo ls /opt/kasm/1.17.0/log/

# Per-container
docker logs kasm_proxy --tail 50
docker logs kasm_agent --tail 50
docker logs adept-kasm-http --tail 50

# Follow agent when spawning sessions
docker logs -f kasm_agent
```

## Database access

```bash
docker exec -it kasm_db psql -U kasmapp -d kasm
```

## Backup

```bash
# DB backup (use Kasm utility)
sudo /opt/kasm/current/bin/utils/db_backup

# Profiles
sudo tar -czf /data/adept/kasm-profiles-backup-$(date +%F).tar.gz -C /data/adept/kasm profiles/
```

## Upgrade path

Use Kasm's `upgrade.sh` from a new release tarball — do not hand-edit platform compose for upgrades.

## Firewall (OCI / iptables)

If users cannot reach 8090 from VCN:

```bash
sudo iptables -I INPUT 1 -s 10.0.0.0/16 -p tcp --dport 8090 -j ACCEPT
sudo iptables -I INPUT 1 -s 10.0.0.0/16 -p tcp --dport 9443 -j ACCEPT
sudo netfilter-persistent save
```

Also open ports **8090** and **9443** on the OCI NSG for the instance subnet.

## Disk monitoring

```bash
df -h / /data
docker system df
sudo du -sh /data/docker /data/containerd
```

Alert if `/` goes above 80% — see [04-docker-storage.md](04-docker-storage.md).
