#!/usr/bin/env bash
set -e

echo "=== Initializing Ubuntu 24.04 Container ==="

# 1. Setup root password
PASS="${SSH_PASSWORD:-UbuntuRailway2026!}"
echo "root:$PASS" | chpasswd
echo "🔒 Root password set."

# 2. Setup SSH Privilege Separation Directory & Host Keys
mkdir -p /run/sshd /var/run/sshd /root/.ssh
chmod 0755 /run/sshd /var/run/sshd
chmod 0700 /root/.ssh
ssh-keygen -A

# 3. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key."
fi

# 4. Write clean sshd_config on Port 22
rm -rf /etc/ssh/sshd_config.d/*
cat << 'EOF' > /etc/ssh/sshd_config
Port 22
ListenAddress 0.0.0.0
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
UsePAM no
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# 5. Start OpenSSH Server in background on Port 22
echo "🚀 Starting OpenSSH Server on port 22..."
/usr/sbin/sshd -D -e &
SSH_PID=$!

# 6. Start Web Terminal on port 8080 (NEVER port 22)
WEB_PORT="8080"
if [ -n "$PORT" ] && [ "$PORT" != "22" ]; then
    WEB_PORT="$PORT"
fi

USER_NAME="${WEB_TERMINAL_USER:-root}"

echo "======================================================"
echo "🚀 Ubuntu 24.04 LTS VPS Container is online!"
echo "🔑 SSH Server listening on port: 22"
echo "📡 Web Terminal listening on port: $WEB_PORT"
echo "======================================================"

# 7. Start Web Terminal in foreground
exec /usr/local/bin/ttyd -p "${WEB_PORT}" -c "${USER_NAME}:${PASS}" -W bash
