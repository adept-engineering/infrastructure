#!/usr/bin/env bash
# One-time bootstrap for Adept Dev workspace (runs as root on first_launch).
set -euo pipefail

resolve_home() {
  if [[ -n "${KASM_USER:-}" ]]; then
    local u
    u=$(echo "$KASM_USER" | sed -r 's#[^a-zA-Z0-9._-]#_#g' | cut -c1-32)
    [[ -d "/home/$u" ]] && { echo "/home/$u"; return; }
  fi
  if [[ -n "${HOME:-}" && -d "$HOME" && "$HOME" != "/home/kasm-user" ]]; then
    echo "$HOME"
    return
  fi
  echo "/home/kasm-user"
}

USER_HOME=$(resolve_home)
MARKER="${USER_HOME}/.adept-dev/installed-v3"
ADEPT_DIR="${USER_HOME}/.adept-dev"
DESKTOP="${USER_HOME}/Desktop"

mkdir -p "$ADEPT_DIR" "$DESKTOP" "${USER_HOME}/Applications"

refresh_shortcuts() {
  desktop_shortcut() {
    local file="$1" name="$2" exec_cmd="$3"
    cat >"$file" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Exec=${exec_cmd}
Terminal=false
EOF
    chmod +x "$file"
  }
  desktop_shortcut "$DESKTOP/cursor.desktop" "Cursor" "cursor"
  desktop_shortcut "$DESKTOP/visual-studio-code.desktop" "Visual Studio Code" "code"
  desktop_shortcut "$DESKTOP/claude-code.desktop" "Claude Code" "xfce4-terminal --hold -e claude"
  desktop_shortcut "$DESKTOP/antigravity.desktop" "Antigravity" "xdg-open https://antigravity.google/download"
  desktop_shortcut "$DESKTOP/devin.desktop" "Devin" "xdg-open https://app.devin.ai/"
}

[[ -f "$MARKER" ]] && { refresh_shortcuts; exit 0; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl ca-certificates gnupg wget \
  libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils \
  tar xz-utils git apt-transport-https software-properties-common

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi

if ! command -v claude >/dev/null 2>&1; then
  npm install -g @anthropic-ai/claude-code || true
fi

if ! command -v code >/dev/null 2>&1; then
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
  apt-get update -qq
  apt-get install -y -qq code || true
fi

if ! command -v cursor >/dev/null 2>&1; then
  TMPDEB="/tmp/cursor.deb"
  curl -fsSL "https://downloader.cursor.sh/linux/deb/x64" -o "$TMPDEB" \
    || curl -fsSL "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/1.0" -o "$TMPDEB" \
    || true
  if [[ -s "$TMPDEB" ]]; then
    dpkg -i "$TMPDEB" 2>/dev/null || apt-get install -f -y -qq
  fi
fi

refresh_shortcuts

cat >"$ADEPT_DIR/README.txt" <<EOF
Adept Dev — full stack workspace
Home: ${USER_HOME}

Installed on first launch:
  • Cursor IDE
  • Visual Studio Code
  • Claude Code (terminal: claude)
  • Antigravity — desktop shortcut (Google sign-in)
  • Devin — web app shortcut (Cognition sign-in)

Use Persistent Profile so tools and logins survive between sessions.
EOF

owner=$(basename "$USER_HOME")
chown -R "${owner}:${owner}" "$ADEPT_DIR" "$DESKTOP" "${USER_HOME}/.npm" 2>/dev/null || true
touch "$MARKER"
