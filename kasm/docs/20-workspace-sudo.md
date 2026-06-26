# Workspace sudo (passwordless)

Inside a Kasm desktop session you are **`kasm-user`** — a Linux account in the container. That is **not** the same as your Adept login email/password on https://workspaces.adeptengr.com/.

## What we configured

All **Desktop** workspace images have Docker Exec Config set so new sessions grant:

```text
kasm-user ALL=(ALL) NOPASSWD: ALL
```

You can run admin commands without a sudo password:

```bash
sudo apt update
sudo apt install -y curl
```

## If sudo still asks for a password

1. **End the session** (dashboard → session menu → destroy) and start a **new** one — `first_launch` runs only when the container is created.
2. Or on the server (admin):

   ```bash
   ~/workspace/kasm/scripts/enable-workspace-sudo.sh --live
   ```

## Re-apply after Kasm upgrade

```bash
~/workspace/kasm/scripts/enable-workspace-sudo.sh
```

`start-all.sh` runs this automatically on boot.

## Security note

Passwordless sudo inside an isolated session container is standard for dev desktops. Users still cannot escape the container or access the host without a separate vulnerability.
