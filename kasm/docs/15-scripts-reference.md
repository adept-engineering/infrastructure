# Scripts Reference

All scripts source `lib/common.sh` and read server `.env` for admin credentials (never commit `.env`).

| Script | Purpose |
|--------|---------|
| `start-all.sh` | Boot stack after reboot (docker, Kasm, nginx, governor, sudo) |
| `healthcheck.sh` | Verify HTTPS, Kasm proxy, containers, disk |
| `install-host-nginx.sh` | One-shot: nginx + Let's Encrypt for workspaces domain |
| `generate-workspaces-certs.sh` | Issue/expand TLS cert (root) |
| `renew-workspaces-certs.sh` | Cert renewal (cron) |
| `create-user.sh` | Create user by email (admin API) |
| `apply-user-identity.sh` | Linux `whoami` + sudo via exec_config |
| `apply-user-resources.sh` | Per-user RAM tiers from `config/user-resources.env` |
| `provision-dev-workspaces.sh` | Admin-gated **Adept Dev** workspace (16 GB + tools) |
| `sync-dev-access.sh` | Grant/revoke Adept Dev from `config/dev-access.env` |
| `grant-dev-access.sh` / `revoke-dev-access.sh` | One-user Adept Dev access |
| `apply-branding.sh` | Sync Adept branding to Kasm + nginx |
| `resource-governor.sh` | Rebalance per-session RAM/CPU |
| `provision-adept-users.sh` | Bulk test users adept-u01..05 |
| `destroy-all-sessions.sh` | End all workspace sessions |
| `e2e-test.sh` | Full validation |
| `install-cron.sh` | Schedule governor every 2 min |
| `test-branding.sh` / `test-branding-all.sh` | Branding smoke tests |

## Typical workflows

**New deploy / after reboot:**
```bash
source ~/workspace/kasm/.env
./scripts/start-all.sh
```

**Onboard a user:** see [21-onboarding.md](21-onboarding.md)
```bash
./scripts/create-user.sh name@adeptengr.com 'First' 'Last'
```

**Validate everything:**
```bash
./scripts/e2e-test.sh
```

## Configuration

Tune in `config/adept.defaults.env`. Secrets in `env.template` → copy to `.env` on server only.
