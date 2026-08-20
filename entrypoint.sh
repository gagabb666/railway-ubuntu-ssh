#!/usr/bin/env bash
set -e

# 1. Setup root password
if [ -n "$SSH_PASSWORD" ]; then
    echo "root:$SSH_PASSWORD" | chpasswd
    echo "🔒 SSH root password set from environment variable."
else
    DEFAULT_PASS="UbuntuRailway2026!"
    echo "root:$DEFAULT_PASS" | chpasswd
    echo "⚠️ No SSH_PASSWORD supplied. Default password set: $DEFAULT_PASS"
fi

# 2. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key to /root/.ssh/authorized_keys."
fi

# 3. Determine Ports avoiding any collision
# SSH will listen on Port 22 and Port 2222
SSH_PORT="22"

# If Railway passed PORT=22 to the container for HTTP, set Web Terminal to 8080 so SSH owns 22
if [ "$PORT" = "22" ] || [ -z "$PORT" ]; then
    WEB_PORT="8080"
else
    WEB_PORT="$PORT"
fi

WEB_USER="${WEB_TERMINAL_USER:-root}"
WEB_PASS="${WEB_TERMINAL_PASSWORD:-${SSH_PASSWORD:-UbuntuRailway2026!}}"

# Ensure sshd privilege directory exists
mkdir -p /var/run/sshd

# Configure sshd to listen on both 22 and 2222
sed -i 's/^#\?Port .*/Port 22\nPort 2222/' /etc/ssh/sshd_config || echo -e "Port 22\nPort 2222" >> /etc/ssh/sshd_config

# 4. Generate dynamic supervisord configuration
cat <<EOF > /etc/supervisor/conf.d/supervisord.conf
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
echo "🔑 SSH Server listening on ports: 22 & 2222"
echo "📡 Web Terminal listening on port: $WEB_PORT"
echo "======================================================"

exec "$@"
