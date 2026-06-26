# User signup and account management (Kasm CE)

> **Onboarding guide:** [21-onboarding.md](21-onboarding.md)

## Self-service signup (`/#/signup`)

Kasm **Community Edition does not license** the `subscriptions/createAccount` API. If you open:

```
https://workspaces.adeptengr.com/#/signup
```

the form may appear, but submission fails with **Access Denied — feature not licensed**.

**For Adept:** create users as admin. Do not rely on public signup on CE.

## Admin account

| Field | Value |
|-------|--------|
| URL | https://workspaces.adeptengr.com/ |
| Email / username | `KASM_ADMIN_USER` in server `.env` |
| Password | `KASM_ADMIN_PASSWORD` in server `.env` (gitignored) |

Admin UI: log in → **ADMIN** tab (users, workspaces, diagnostics).

## Create a new user (CLI)

```bash
source ~/workspace/kasm/.env
~/workspace/kasm/scripts/create-user.sh email@adeptengr.com 'First' 'Last'
```

Optional fourth argument sets the password; otherwise one is generated.

Or in the UI: **ADMIN → Access Management → Users → Add**.

## Removed test users

The auto-provisioned `adept-u01` … `adept-u05` and `user@kasm.local` accounts were **deleted**. Passwords in `.adept-users.env` were cleared.

## Session errors — causes and fixes

### “No Agent slots available”

- Server `max_simultaneous_sessions` is **5**.
- Old test runs left **5 running sessions** (e.g. adept-u01 had 3 at once).
- **Fix:** end sessions in **ADMIN → Sessions**, or:

```bash
source ~/workspace/kasm/.env
~/workspace/kasm/scripts/destroy-all-sessions.sh
```

### Workspace loads 100% then returns to dashboard

- **Fixed (2026-06-25):** serve users at **https://workspaces.adeptengr.com/** with `zones.proxy_port = 443`.
- Kasm hardcodes `https://` for stream URLs; plain HTTP `:8090` failed silently.
- See [18-session-connect-fix.md](18-session-connect-fix.md) and [19-https-domain.md](19-https-domain.md).

### “Access Denied — not licensed” in Admin logs

Harmless on CE when using licensed-only features (advanced logging export, self-signup, some branding APIs). Core workspaces still work.

## Test user (optional)

A temporary account exists for validation:

- `test.user@adeptengr.com` — delete in **ADMIN → Users** when done.

## Verify

```bash
source ~/workspace/kasm/.env
~/workspace/kasm/scripts/healthcheck.sh
~/workspace/kasm/scripts/test-branding-all.sh
```
