# E2E Test Results

**Latest run:** 2026-06-25 — **PASSED**

Run: `source ~/workspace/kasm/.env && ./scripts/e2e-test.sh`

## Results summary

| Phase | Test | Result |
|-------|------|--------|
| 1 | Healthcheck (HTTP/HTTPS/containers/disk) | PASS |
| 2 | Autoset passwords + login all 5 users | PASS |
| 3 | Clean session slate | PASS |
| 4 | 5 concurrent sessions (different images) | PASS |
| 4 | RAM under load | 13% used |
| 5 | 3 users → surplus RAM (10 GiB vs 5 GiB) | PASS |
| 6 | External HTTP `http://10.0.5.36:8090` | PASS |

## Session matrix (phase 4)

| User | Workspace |
|------|-----------|
| adept-u01 | Ubuntu Noble |
| adept-u02 | Ubuntu Jammy |
| adept-u03 | Terminal |
| adept-u04 | Visual Studio Code |
| adept-u05 | Firefox |

## Dynamic RAM (phase 5)

| Scenario | Ubuntu Noble RAM |
|----------|------------------|
| 5 users planned | 5188 MiB |
| 3 users active | 10240 MiB (governor reallocates spare RAM) |

## Credentials

Auto-generated passwords: `~/workspace/kasm/.adept-users.env` (gitignored).

Rotate: `./scripts/provision-adept-users.sh --rotate`

## Logs

`~/workspace/kasm/logs/e2e-*.log`
