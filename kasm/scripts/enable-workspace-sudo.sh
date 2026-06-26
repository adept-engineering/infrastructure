#!/usr/bin/env bash
# Passwordless sudo for kasm-user inside workspace containers (all Desktop images).
# Kasm login password != Linux user password; this lets users run sudo apt without a prompt.
#
# Applies via images.exec_config "first_launch" (runs once per new session container).
# Existing sessions: end them and launch again, or run with --live to patch running containers.
#
# Usage:
#   ./enable-workspace-sudo.sh          # update DB for all Desktop workspaces
#   ./enable-workspace-sudo.sh --live   # also patch currently running session containers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

LIVE=0
[[ "${1:-}" == "--live" ]] && LIVE=1

# Debian/Ubuntu — sudo is already in the image; only sudoers line needed.
EXEC_DEBIAN='{"first_launch":{"user":"root","cmd":"bash -c '\''grep -q \"kasm-user ALL=(ALL) NOPASSWD: ALL\" /etc/sudoers 2>/dev/null || echo \"kasm-user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'\''"}}'

# RHEL family
EXEC_DNF='{"first_launch":{"user":"root","cmd":"bash -c '\''(command -v sudo >/dev/null || (dnf install -y sudo 2>/dev/null || yum install -y sudo)); grep -q \"kasm-user ALL=(ALL) NOPASSWD: ALL\" /etc/sudoers 2>/dev/null || echo \"kasm-user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'\''"}}'

# Alpine
EXEC_APK='{"first_launch":{"user":"root","cmd":"bash -c '\''(command -v sudo >/dev/null || (apk add --no-cache sudo)); grep -q \"kasm-user ALL=(ALL) NOPASSWD: ALL\" /etc/sudoers 2>/dev/null || echo \"kasm-user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'\''"}}'

pick_exec_config() {
  local name="$1"
  case "$name" in
    Ubuntu*|Debian*|Docker*|CUDA*|Kali*|Parrot*|Alpine*)
      if [[ "$name" == Alpine* ]]; then
        echo "$EXEC_APK"
      elif [[ "$name" == Kali* || "$name" == Parrot* ]]; then
        echo "$EXEC_DEBIAN"
      else
        echo "$EXEC_DEBIAN"
      fi
      ;;
    Fedora*|Rocky*|Alma*|Oracle*|OpenSUSE*)
      echo "$EXEC_DNF"
      ;;
    *)
      echo "$EXEC_DEBIAN"
      ;;
  esac
}

patch_running_container() {
  local cname="$1"
  docker exec -u root "$cname" bash -c \
    'grep -q "kasm-user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null || echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers' \
    2>/dev/null || return 1
  docker exec -u kasm-user "$cname" sudo -n true 2>/dev/null
}

adept_log "Enabling passwordless sudo on Desktop workspace images"

while IFS='|' read -r image_id friendly_name; do
  [[ -n "$image_id" ]] || continue
  cfg=$(pick_exec_config "$friendly_name")
  # Escape single quotes for SQL
  cfg_sql=${cfg//\'/\'\'}
  docker exec kasm_db psql -U kasmapp -d kasm -q -c \
    "UPDATE images SET exec_config = '${cfg_sql}'::jsonb WHERE image_id = '${image_id}';"
  adept_log "  ${friendly_name}"
done < <(docker exec kasm_db psql -U kasmapp -d kasm -tAc \
  "SELECT image_id || '|' || friendly_name FROM images
   WHERE image_type = 'Container' AND categories::text ILIKE '%Desktop%'
   ORDER BY friendly_name;")

if [[ "$LIVE" -eq 1 ]]; then
  adept_log "Patching running session containers"
  while read -r cname; do
    [[ -n "$cname" ]] || continue
    if patch_running_container "$cname"; then
      adept_log "  OK ${cname}"
    else
      adept_log "  SKIP ${cname}"
    fi
  done < <(docker ps --format '{{.Names}}' | grep -vE '^kasm_' || true)
fi

adept_log "Done. End existing sessions and start new ones for first_launch on fresh containers."
