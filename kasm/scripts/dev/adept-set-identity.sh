#!/bin/bash
# Idempotent: rename kasm-user -> KASM_USER and use /home/<username> (not /home/kasm-user).
# Kasm still syncs persistent profiles to /home/kasm-user; we bind-mount that at the real home.
# Run as root.
KASM_USER="${KASM_USER:-}"
if [[ -z "$KASM_USER" && -r /proc/1/environ ]]; then
  KASM_USER=$(tr '\0' '\n' < /proc/1/environ | sed -n 's/^KASM_USER=//p' | head -1)
fi
[[ -n "$KASM_USER" ]] || exit 0

# POSIX-safe Linux username (no dots — breaks su/pam/terminals)
u=$(echo "$KASM_USER" | sed -r 's#[^a-zA-Z0-9_-]#_#g' | cut -c1-32)
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
  if ! usermod -l "$u" kasm-user; then
    echo "[adept-set-identity] usermod -l failed (user likely busy), falling back to /etc/passwd edit" >&2
    sed -i "s/^kasm-user:/${u}:/" /etc/passwd
  fi
  if getent group kasm-user >/dev/null 2>&1; then
    groupmod -n "$u" kasm-user || echo "[adept-set-identity] groupmod -n failed" >&2
  fi
fi

if [[ -d "$OLD_HOME" ]]; then
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
      || sed -i "s#^${u}:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*#${u}:x:1000:1000::${NEW_HOME}:/bin/bash#" /etc/passwd
  fi
fi

for cfg in "$NEW_HOME/.config/user-dirs.dirs" "$OLD_HOME/.config/user-dirs.dirs"; do
  [[ -f "$cfg" ]] && sed -i "s|/home/kasm-user|${NEW_HOME}|g" "$cfg" 2>/dev/null || true
done

cat >/etc/profile.d/adept-home.sh <<EOF
# Adept: HOME matches Kasm username (not /home/kasm-user)
export USER="${u}"
export LOGNAME="${u}"
export HOME="${NEW_HOME}"
if [ "\$PWD" = "${OLD_HOME}" ] || [ "\$PWD" = "${OLD_HOME}/" ]; then
  cd "${NEW_HOME}" 2>/dev/null || true
elif [ "\${PWD#${OLD_HOME}/}" != "\$PWD" ]; then
  cd "${NEW_HOME}/\${PWD#${OLD_HOME}/}" 2>/dev/null || true
fi
EOF
chmod 644 /etc/profile.d/adept-home.sh

mkdir -p /etc/environment.d
echo "HOME=${NEW_HOME}" > /etc/environment.d/99-adept-home.conf
if [[ -f /etc/environment ]]; then
  grep -v '^HOME=' /etc/environment > /tmp/adept-environment 2>/dev/null || true
  echo "HOME=${NEW_HOME}" >> /tmp/adept-environment
  mv /tmp/adept-environment /etc/environment
else
  echo "HOME=${NEW_HOME}" > /etc/environment
fi

if ! grep -q 'adept-home.sh' /etc/bash.bashrc 2>/dev/null; then
  cat >>/etc/bash.bashrc <<'EOF'

# Adept: apply Kasm username home in all bash shells
[ -f /etc/profile.d/adept-home.sh ] && . /etc/profile.d/adept-home.sh
EOF
fi

# Do not edit $OLD_HOME/.bashrc — it is the persistent Kasm profile and breaks
# Terminal / VS Code startup when sourced during container entrypoint.

echo "[adept-set-identity] done: user=$(id -un "$u" 2>/dev/null || echo "$u") home=${NEW_HOME}"
exit 0
