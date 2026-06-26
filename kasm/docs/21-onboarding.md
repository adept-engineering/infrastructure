# User onboarding (admin guide)

Kasm **Community Edition** has no public self-service signup. An admin must create every account.

## Prerequisites

- Admin login at https://workspaces.adeptengr.com/
- Server `.env` with `KASM_ADMIN_USER` and `KASM_ADMIN_PASSWORD` (see `env.template`)

## Option A — Admin UI (recommended)

1. Log in as admin.
2. **ADMIN** → **Access Management** → **Users** → **Add User**.
3. Set:
   - **Username / email:** `firstname.lastname@adeptengr.com` (email is the login ID)
   - **First / last name**
   - **Password:** meet Kasm policy (length + special character)
   - **Realm:** local
4. Assign workspace images (e.g. **Ubuntu Jammy**) under group/image permissions if restricted.
5. Send credentials to the user over a **secure channel** (not email if policy forbids).

## Option B — CLI on Desktop-server

```bash
cd ~/workspace/kasm
source .env
./scripts/create-user.sh jane.doe@adeptengr.com 'Jane' 'Doe'
# or with explicit password:
./scripts/create-user.sh jane.doe@adeptengr.com 'Jane' 'Doe' 'SecurePass1!'
```

## What to tell new users

| Topic | Detail |
|-------|--------|
| URL | https://workspaces.adeptengr.com/ |
| Login | Their **email** + password you set |
| Desktop user | `kasm-user` inside the session (not their login email) |
| `sudo` | Passwordless — `sudo apt update` works with no extra password |
| Profiles | Files persist under `/data/adept/kasm/profiles/{username}` |
| Signup page | Disabled on CE — ignore `/#/signup` |

## Offboarding

1. Admin UI → Users → disable or delete user.
2. Optional: remove profile data on server:

   ```bash
   sudo rm -rf /data/adept/kasm/profiles/<username>
   ```

## Bulk provisioning (optional)

`./scripts/provision-adept-users.sh` creates `adept-u01`…`adept-u05` with random passwords in `.adept-users.env` (gitignored). Prefer `create-user.sh` for real named accounts.
