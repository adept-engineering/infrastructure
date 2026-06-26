# Session connect fix (Play → 100% → back to dashboard)

## Symptom

User clicks **Play** on a workspace. Progress reaches 100%, then returns to the dashboard. No desktop appears.

## Resolution (2026-06-25)

**Fixed by moving to `https://workspaces.adeptengr.com`** — see [19-https-domain.md](19-https-domain.md).

The HTTP `:8090` workaround (bundle patching) is retired. Host nginx terminates Let's Encrypt TLS on `:443` and proxies to Kasm `:9443`.

## Original issue (HTTP :8090)

Kasm’s web client **hardcodes `https://`** when building the VNC iframe URL:

```
https://localhost:8090/desktop/<id>/vnc/vnc.html
```

Port **8090** is plain **HTTP** (Adept nginx proxy). The browser cannot complete TLS on that port, so the stream fails silently.

## Historical workaround (retired)

1. Zone `proxy_port = 8090` + nginx `sub_filter` on `index.bundle.js`
2. Required users to stay on one hostname (localhost vs IP)

Superseded by HTTPS on `workspaces.adeptengr.com` with `proxy_port = 443`.
3. **Branding** `sub_filter` limited to `/api/login_settings` and HTML only — not all JSON.

## User steps

1. Use **one URL always**: `http://localhost:8090` **or** `http://10.0.5.36:8090` (do not mix localhost and 127.0.0.1).
2. Hard refresh: **Ctrl+Shift+R**.
3. **ADMIN → Sessions** → delete old sessions (or run `destroy-all-sessions.sh`).
4. Log in as user → click **Play** on the **left session card** (blue play icon), not only the grid tile.
5. Wait for the Ubuntu desktop (may take 30–60s first launch).

## If it still fails

- Unregister service worker (DevTools → Application → Service Workers).
- Try `http://10.0.5.36:8090` on the same network instead of SSH tunnel.
- Check **ADMIN → Sessions** — max **5** concurrent; delete extras.
