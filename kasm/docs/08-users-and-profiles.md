# Users and Persistent Profiles

See **[21-onboarding.md](21-onboarding.md)** for creating users.

## Accounts

| Role | Username | Notes |
|------|----------|-------|
| Admin | `KASM_ADMIN_USER` in server `.env` | Full admin UI |
| Users | `email@adeptengr.com` | Created by admin (CE — no public signup) |

Passwords live in server `.env` and `.adept-users.env` only — never committed to git.

### Create a user

**UI:** https://workspaces.adeptengr.com/ → ADMIN → Users → Add User

**CLI:**
```bash
source ~/workspace/kasm/.env
./scripts/create-user.sh name@adeptengr.com 'First' 'Last'
```

## Persistent profiles

Without persistent profiles, user data is lost when a session ends.

### Configure (Admin UI)
