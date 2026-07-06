#!/usr/bin/env bash
# One-time bootstrap for Adept Dev workspace (runs as root on first_launch).
# Idempotent: guarded by ~/.adept-dev/installed
set -euo pipefail

MARKER="/home/kasm-user/.adept-dev/installed"
ADEPT_DIR="/home/kasm-user/.adept-dev"
DESKTOP="/home/kasm-user/Desktop"

mkdir -p "$ADEPT_DIR" "$DESKTOP" /home/kasm-user/Applications
[[ -f "$MARKER" ]] && exit 0

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  curl ca-certificates gnupg \
  libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils \
  tar xz-utils git

# Node.js 20 LTS (Claude Code + general dev)
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi

# Claude Code CLI
if ! command -v claude >/dev/null 2>&1; then
  npm install -g @anthropic-ai/claude-code || true
fi

# Cursor IDE (.deb)
if ! command -v cursor >/dev/null 2>&1; then
  TMPDEB="/tmp/cursor.deb"
  curl -fsSL "https://downloader.cursor.sh/linux/deb/x64" -o "$TMPDEB" \
    || curl -fsSL "https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/1.0" -o "$TMPDEB" \
    || true
  if [[ -s "$TMPDEB" ]]; then
    dpkg -i "$TMPDEB" 2>/dev/null || apt-get install -f -y -qq
  fi
fi

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
desktop_shortcut "$DESKTOP/claude-code.desktop" "Claude Code" "xfce4-terminal --hold -e claude"
desktop_shortcut "$DESKTOP/antigravity.desktop" "Antigravity" "xdg-open https://antigravity.google/download"
desktop_shortcut "$DESKTOP/devin.desktop" "Devin" "xdg-open https://app.devin.ai/"

cat >"$ADEPT_DIR/README.txt" <<'EOF'
Adept Dev — full stack workspace

Installed on first launch:
  • Cursor IDE
  • Claude Code (terminal: claude)
  • Antigravity — open desktop shortcut to download/sign in (Google account)
  • Devin — web app shortcut (Cognition account)

Use Persistent Profile so tools and logins survive between sessions.
EOF

chown -R kasm-user:kasm-user "$ADEPT_DIR" "$DESKTOP" /home/kasm-user/.npm 2>/dev/null || true
touch "$MARKER"
