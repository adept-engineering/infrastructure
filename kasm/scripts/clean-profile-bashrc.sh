#!/usr/bin/env bash
# Remove Adept identity hooks from persisted Kasm profiles (fixes Terminal / VS Code crash).
set -euo pipefail

PROFILES_ROOT="${PROFILES_ROOT:-/data/adept/kasm/profiles}"
KASM_BASHRC='source $STARTUPDIR/generate_container_user'

clean_one() {
  local rc="$1"
  [[ -f "$rc" ]] || return 0
  if ! grep -q 'adept-home\|adept-set-identity\|adept-identity' "$rc" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$KASM_BASHRC" | sudo tee "$rc" >/dev/null
  echo "cleaned: $rc"
}

while IFS= read -r -d '' rc; do
  clean_one "$rc"
done < <(find "$PROFILES_ROOT" -name .bashrc -print0 2>/dev/null)

echo "Done. Profile .bashrc files restored to standard Kasm template."
