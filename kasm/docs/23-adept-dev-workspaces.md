# Adept Dev workspace (admin-gated)

One **16 GB Ubuntu desktop** with the full recommended dev stack — **not** in All Users. Admin grants access per user.

## What’s included

Same base as the power-user tier (Ubuntu Jammy, sudo, Linux username from Kasm login), plus on **first launch**:

| Tool | Setup |
|------|--------|
| **Cursor** | `.deb` install + desktop shortcut |
| **Claude Code** | Node 20 + global CLI + desktop shortcut |
| **Antigravity** | Desktop shortcut → official download (Google sign-in) |
| **Devin** | Desktop shortcut → web app (Cognition sign-in) |

Persistent profile: `/data/adept/kasm/profiles/{username}/adept-dev`

Install logic: `scripts/dev/install-adept-stack.sh` (idempotent; runs once per profile).

## Who sees it

Only users listed in `config/dev-access.env` (group **Adept Dev**). Everyone else keeps the normal catalog only (e.g. Ubuntu Jammy 2 GB / 16 GB).

## Ops

```bash
# (Re)create workspace definition
~/workspace/kasm/scripts/provision-dev-workspaces.sh

# Sync access from config
~/workspace/kasm/scripts/sync-dev-access.sh

# One user
~/workspace/kasm/scripts/grant-dev-access.sh remikuti
~/workspace/kasm/scripts/revoke-dev-access.sh remikuti
```

`start-all.sh` runs `sync-dev-access.sh` when `config/dev-access.env` exists.

## User notes

- Launch with **Persistent Profile** so installs and logins survive.
- First session needs network (downloads).
- Antigravity/Devin require the user’s own Google/Cognition accounts in the browser.
