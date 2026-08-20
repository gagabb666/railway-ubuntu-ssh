#!/usr/bin/env bash
set -e

# 1. Setup root password
if [ -n "$SSH_PASSWORD" ]; then
    echo "root:$SSH_PASSWORD" | chpasswd
    echo "🔒 SSH root password set from environment variable (SSH_PASSWORD)."
else
    DEFAULT_PASS="UbuntuRailway2026!"
    echo "root:$DEFAULT_PASS" | chpasswd
    echo "⚠️ No SSH_PASSWORD variable supplied. Default password set: $DEFAULT_PASS"
fi

# 2. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key to /root/.ssh/authorized_keys."
fi

# 3. Setup Web Terminal Credentials
WEB_USER="${WEB_TERMINAL_USER:-root}"
WEB_PASS="${WEB_TERMINAL_PASSWORD:-${SSH_PASSWORD:-UbuntuRailway2026!}}"
PORT_NUM="${PORT:-8080}"

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
command=/usr/local/bin/ttyd -p ${PORT_NUM} -c ${WEB_USER}:${WEB_PASS} -W bash
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

echo "======================================================"
echo "🚀 Ubuntu 24.04 LTS VPS Container is starting!"
echo "📡 Web Terminal listening on port: $PORT_NUM (User: $WEB_USER)"
echo "🔑 SSH Server listening on port: 22"
echo "======================================================"

exec "$@"
