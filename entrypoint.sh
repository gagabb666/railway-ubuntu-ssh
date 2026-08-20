#!/usr/bin/env bash
set -e

# 1. Setup root password
PASS="${SSH_PASSWORD:-UbuntuRailway2026!}"
echo "root:$PASS" | chpasswd
echo "🔒 Root password configured."

# 2. Setup SSH Privilege Separation Directory & Host Keys
mkdir -p /run/sshd /var/run/sshd /root/.ssh
chmod 0755 /run/sshd /var/run/sshd
chmod 0700 /root/.ssh
ssh-keygen -A

# 3. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key to /root/.ssh/authorized_keys."
fi

# 4. Clean drop-ins & enforce clear, permissive OpenSSH Server config
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

# 5. Setup Web Terminal Ports
if [ "$PORT" = "22" ] || [ -z "$PORT" ]; then
    WEB_PORT="8080"
else
    WEB_PORT="$PORT"
fi

WEB_USER="${WEB_TERMINAL_USER:-root}"
WEB_PASS="${WEB_TERMINAL_PASSWORD:-$PASS}"

# 6. Generate dynamic supervisord configuration
cat << EOF > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:sshd]
command=/usr/sbin/sshd -D -e
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:ttyd]
command=/usr/local/bin/ttyd -p ${WEB_PORT} -c ${WEB_USER}:${WEB_PASS} -W bash
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

echo "======================================================"
echo "🚀 Ubuntu 24.04 LTS VPS Container is starting!"
echo "🔑 SSH Server listening on port: 22"
echo "📡 Web Terminal listening on port: $WEB_PORT"
echo "======================================================"

exec "$@"
