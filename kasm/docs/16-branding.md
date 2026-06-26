# Adept Branding

Kasm CE blocks the branding API (`not licensed`), so branding is applied via:

1. **Database** — `branding_configs` row (title, caption, logo paths)
2. **Asset replace** — Adept logo/favicon copied into `kasm_proxy:/srv/www/img/`
3. **Host nginx** — title, CSS, and favicon injected on `https://workspaces.adeptengr.com/`

## Apply / refresh

```bash
~/workspace/kasm/scripts/apply-branding.sh
```

Runs automatically from `start-all.sh`.

## Verify branding

```bash
source ~/workspace/kasm/.env
~/workspace/kasm/scripts/test-branding-all.sh
```

This runs 15 static/API checks plus a headless browser login test. Screenshot saved under `logs/branding-browser-*/login.png`.

## Files

| File | Purpose |
|------|---------|
| `branding/logo.svg` | Login + header logo |
| `branding/favicon.png` | Browser tab icon |
| `branding/login-splash.svg` | Right-panel gradient background |
| `branding/adept.css` | Adept blue theme + login polish |
| `branding/adept.js` | Patches login API + hides Kasm footer text |

## What users see

- **Title:** Adept Engineering Solutions
- **Caption:** Secure virtual workspaces for teams
- **Company name:** Adept Engineering Solutions (bold, light blue `#6ec8ff` above tagline)
- **Splash:** Custom Adept blue gradient panel (replaces Kasm mesh)
- **Logo:** Adept AE monogram (#01509A)
- **Typography:** Inter font, refined form + button styling
- **Removed:** “Powered by Kasm Workspaces” and default tagline

## Note

Use **https://workspaces.adeptengr.com/** for the full branded experience. Internal Kasm `:9443` has logo swap but not CSS injection.

If the company name is missing on the login splash, hard-refresh (`Ctrl+Shift+R`) or clear site data — `adept.js` injects it into `.logo-bottom-txt`.

If the page shows only a loading spinner after branding changes:

1. Hard refresh: **Ctrl+Shift+R**
2. Clear site data for the host (DevTools → Application → Storage → Clear)
3. Unregister the Kasm service worker (DevTools → Application → Service Workers → Unregister)

The Adept `adept.js` no longer intercepts `fetch` (that caused stuck loads). Branding comes from nginx API patches + CSS.
