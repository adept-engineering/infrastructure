#!/usr/bin/env bash
# Passwordless sudo in workspace containers (delegates to apply-user-identity.sh).
exec "$(dirname "$0")/apply-user-identity.sh" "$@"
