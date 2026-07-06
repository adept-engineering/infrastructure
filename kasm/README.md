# Adept Kasm Workspaces — Desktop-server

Browser-based isolated virtual desktops for ~5 concurrent Adept users ([Kasm CE 1.17.0](https://kasmweb.com/)).

## Quick reference

| Item | Value |
|------|-------|
| User URL | `https://workspaces.adeptengr.com/` |
| Admin login | Email in `KASM_ADMIN_USER` (see `.env` on server) |
| User passwords | `.adept-users.env` on server (gitignored) |
| Profiles | `/data/adept/kasm/profiles/{username}` |
| Platform | `/opt/kasm/` (installer) |
| This tree | `kasm/` in [adept-engineering/infrastructure](https://github.com/adept-engineering/infrastructure) |

## First-time server setup

```bash
cp env.template .env    # fill secrets on server only
source .env
sudo ./scripts/install-host-nginx.sh   # TLS + host nginx (once)
./scripts/start-all.sh
```

## Day-to-day operations

```bash
cd ~/workspace/kasm   # or deployed path on server
source .env

./scripts/start-all.sh                 # after reboot
./scripts/healthcheck.sh
./scripts/create-user.sh email@adeptengr.com 'First' 'Last'
./scripts/enable-workspace-sudo.sh     # passwordless sudo in desktops
./scripts/resource-governor.sh
./scripts/install-cron.sh
```

## Documentation

See **[docs/README.md](docs/README.md)** — architecture, HTTPS, onboarding, troubleshooting.

## Layout

On **Desktop-server**, `~/workspace/kasm` is a symlink to this directory inside the git repo:

```
~/workspace/
├── infrastructure/          # git clone — push changes from here
│   └── kasm/                # canonical copy (this tree)
└── kasm -> infrastructure/kasm
```

Server-only files (gitignored): `.env`, `.adept-users.env`, `logs/`

**Workflow:** edit under `~/workspace/kasm` (or `~/workspace/infrastructure/kasm`), then:

```bash
cd ~/workspace/infrastructure
git add kasm && git commit -m "..." && git push origin main
```

```
kasm/
├── config/adept.defaults.env
├── letsencrypt/                  # certbot domain/email lists
├── nginx/                        # host nginx site configs
├── branding/                     # Adept UI assets
├── scripts/
├── docs/
├── env.template                  # safe template (no secrets)
├── .env                          # server only — gitignored
└── .adept-users.env              # server only — gitignored
```
