# User Password and Username Management

## Password reset (self-service)

Kasm CE includes **built-in profile password change** — no extra plugin required.

### User workflow

1. Log in at https://workspaces.adeptengr.com/
2. Click profile icon (top right) → **Edit Profile**
3. **Reset Password** → enter current password + new password → Save

### Password policy

Kasm enforces passwords with at least one **special character**. Initial Adept passwords use format:

```
AdeptPass01!x  …  AdeptPass05!x
```

Stored in `~/workspace/kasm/.adept-users.env` (gitignored).

### Admin-assisted reset

Admin → Users → select user → set new password.

Or via API:

```bash
curl -sk -X POST "https://10.0.5.36:9443/api/admin/update_user" \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "<admin-email>",
    "token": "<admin-session-token>",
    "target_user": {
      "user_id": "<uuid>",
      "username": "adept-u01",
      "password": "NewSecurePass1!"
    }
  }'
```

Get admin token:

```bash
curl -sk -X POST "https://10.0.5.36:9443/api/authenticate" \
  -H 'Content-Type: application/json' \
  -d '{"username":"<admin-email>","password":"<admin-password>"}'
```

### Group settings applied

| Setting | Value | Effect |
|---------|-------|--------|
| `password_expires` | `0` | No forced password rotation |
| `allow_persistent_profile` | `True` | Users can enable persistent desktops |

## Username change

**Users cannot change their own username** in Kasm CE — this is by design (username is the account identity / profile path key).

### Who can change usernames

- **Administrator** via Admin → Users → Edit
- **Admin API** `POST /api/admin/update_user` with new `username` in `target_user`

### Important when renaming

If using persistent profiles at `/data/adept/kasm/profiles/{username}`:

1. Rename user in Admin UI / API
2. **Rename the profile directory** on disk to match:

```bash
sudo mv /data/adept/kasm/profiles/adept-u05 /data/adept/kasm/profiles/adept-u05-renamed
```

Or the user starts with a fresh profile under the new name.

### E2E verified (2026-06-25)

- Password reset for `adept-u01` via admin API → user login with new password: **OK**
- Username rename `adept-u05` → `adept-u05-renamed` via admin API: **OK**

## Adept users

| Username | Default workspace | Password file |
|----------|-------------------|---------------|
| adept-u01 | Ubuntu Noble | `.adept-users.env` |
| adept-u02 | Ubuntu Jammy | `.adept-users.env` |
| adept-u03 | Terminal | `.adept-users.env` |
| adept-u04 | Visual Studio Code | `.adept-users.env` |
| adept-u05-renamed | Firefox | `.adept-users.env` |

## Scripts

```bash
# Provision users (uses admin API)
~/workspace/kasm/scripts/provision-adept-users.sh

# Full 5-user concurrent test
export KASM_ADMIN_PASSWORD='...'
~/workspace/kasm/scripts/e2e-five-users.sh

# Tear down all sessions
~/workspace/kasm/scripts/destroy-all-sessions.sh
```
