# Adept Kasm Documentation

Operational docs for Kasm Workspaces CE on **Desktop-server** (`workspaces.adeptengr.com`).

## Index

| Doc | What it covers |
|-----|----------------|
| [01-architecture.md](01-architecture.md) | Components and traffic flow |
| [02-preflight-and-layout.md](02-preflight-and-layout.md) | Server checks and directories |
| [03-kasm-install.md](03-kasm-install.md) | `install.sh` and platform layout |
| [04-docker-storage.md](04-docker-storage.md) | `/data/docker` and containerd |
| [05-http-proxy.md](05-http-proxy.md) | **Legacy** Docker HTTP proxy (:8090) |
| [06-tls-certificates.md](06-tls-certificates.md) | Kasm self-signed cert (internal :9443) |
| [07-post-install-fixes.md](07-post-install-fixes.md) | Session limits, tuning |
| [08-users-and-profiles.md](08-users-and-profiles.md) | Users and persistent profiles |
| [09-operations.md](09-operations.md) | Start/stop, logs, cron |
| [10-troubleshooting.md](10-troubleshooting.md) | Symptom → fix |
| [11-network-binding.md](11-network-binding.md) | Ports, firewall, OCI NSG |
| [12-user-password-username.md](12-user-password-username.md) | Password reset |
| [13-e2e-test-results.md](13-e2e-test-results.md) | E2E test results |
| [14-resource-governor.md](14-resource-governor.md) | Dynamic RAM/CPU |
| [15-scripts-reference.md](15-scripts-reference.md) | Script catalog |
| [16-branding.md](16-branding.md) | Adept login branding |
| [17-users-signup-sessions.md](17-users-signup-sessions.md) | CE signup limits, sessions |
| [18-session-connect-fix.md](18-session-connect-fix.md) | Play button / HTTPS fix |
| [19-https-domain.md](19-https-domain.md) | **Production** TLS + nginx |
| [20-workspace-sudo.md](20-workspace-sudo.md) | Passwordless sudo in desktops |
| [21-onboarding.md](21-onboarding.md) | **Admin guide** — add users |

## Quick access

- **URL:** https://workspaces.adeptengr.com/
- **Admin:** `KASM_ADMIN_USER` in server `.env` (gitignored)
- **Add users:** [21-onboarding.md](21-onboarding.md) or `./scripts/create-user.sh`
- **Platform:** `/opt/kasm/current/docker/docker-compose.yaml`

## Server profile

| Item | Value |
|------|-------|
| Hostname | Desktop-server |
| Private IP | 10.0.5.36 |
| Public DNS | workspaces.adeptengr.com → 129.213.100.158 |
| RAM | 31 GiB |
| Docker data-root | `/data/docker` |
| Profiles | `/data/adept/kasm/profiles/{username}` |
| Kasm version | CE 1.17.0 |
