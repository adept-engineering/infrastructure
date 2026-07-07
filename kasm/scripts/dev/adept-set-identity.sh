#!/bin/bash
# Idempotent: rename kasm-user -> KASM_USER and use /home/<username> (not /home/kasm-user).
# Kasm still syncs persistent profiles to /home/kasm-user; we bind-mount that at the real home.
# Run as root.
KASM_USER="${KASM_USER:-}"
if [[ -z "$KASM_USER" && -r /proc/1/environ ]]; then
  KASM_USER=$(tr '\0' '\n' < /proc/1/environ | sed -n 's/^KASM_USER=//p' | head -1)
fi
[[ -n "$KASM_USER" ]] || exit 0

u=$(echo "$KASM_USER" | sed -r 's#[^a-zA-Z0-9._-]#_#g' | cut -c1-32)
[[ -n "$u" && "$u" != "kasm-user" ]] || exit 0

OLD_HOME="/home/kasm-user"
NEW_HOME="/home/$u"

grep -q "kasm-user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null \
  || echo "kasm-user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
grep -q "/usr/local/sbin/adept-set-identity" /etc/sudoers 2>/dev/null \
  || echo "kasm-user ALL=(ALL) NOPASSWD: /usr/local/sbin/adept-set-identity" >> /etc/sudoers
grep -q "^${u} ALL=(ALL) NOPASSWD: ALL" /etc/sudoers 2>/dev/null \
  || echo "${u} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
grep -q "^${u} ALL=(ALL) NOPASSWD: /usr/local/sbin/adept-set-identity" /etc/sudoers 2>/dev/null \
  || echo "${u} ALL=(ALL) NOPASSWD: /usr/local/sbin/adept-set-identity" >> /etc/sudoers

if id kasm-user >/dev/null 2>&1; then
  usermod -l "$u" kasm-user 2>/dev/null || sed -i "s/^kasm-user:/${u}:/" /etc/passwd
  getent group kasm-user >/dev/null 2>&1 && groupmod -n "$u" kasm-user 2>/dev/null || true
fi

if [[ -d "$OLD_HOME" ]]; then
  # Prefer a real bind mount over symlink so UI path bars keep /home/<username>.
  if [[ -L "$NEW_HOME" ]]; then
    rm -f "$NEW_HOME"
  fi
  if ! mountpoint -q "$NEW_HOME" 2>/dev/null; then
    [[ -e "$NEW_HOME" ]] || mkdir -p "$NEW_HOME"
    if ! mount --bind "$OLD_HOME" "$NEW_HOME" 2>/dev/null; then
      rm -rf "$NEW_HOME"
      ln -sfn "$OLD_HOME" "$NEW_HOME"
    fi
  fi
  if id "$u" >/dev/null 2>&1; then
    usermod -d "$NEW_HOME" -s /bin/bash "$u" 2>/dev/null \
      || sed -i "s#^${u}:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\):#${u}:x:\1:${NEW_HOME}:/bin/bash:#" /etc/passwd
  fi
fi

# XDG / desktop paths
for cfg in "$NEW_HOME/.config/user-dirs.dirs" "$OLD_HOME/.config/user-dirs.dirs"; do
  [[ -f "$cfg" ]] && sed -i "s|/home/kasm-user|${NEW_HOME}|g" "$cfg" 2>/dev/null || true
done

cat >/etc/profile.d/adept-home.sh <<EOF
# Adept: HOME matches Kasm username (not /home/kasm-user)
export USER="${u}"
export LOGNAME="${u}"
export HOME="${NEW_HOME}"
if [ "\$PWD" = "${OLD_HOME}" ]; then
  cd "${NEW_HOME}" 2>/dev/null || true
elif [[ "\$PWD" == "${OLD_HOME}/"* ]]; then
  cd "${NEW_HOME}\${PWD#${OLD_HOME}}" 2>/dev/null || true
fi
EOF
chmod 644 /etc/profile.d/adept-home.sh

# X session / file manager
if [[ -d /etc/xdg ]]; then
  mkdir -p /etc/xdg/xfce4
  cat >/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml 2>/dev/null || true
fi

exit 0
