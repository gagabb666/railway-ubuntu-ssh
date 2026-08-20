#!/usr/bin/env bash
set -e

echo "=== Initializing Ubuntu 24.04 Container ==="

# 1. Setup root password
PASS="${SSH_PASSWORD:-UbuntuRailway2026!}"
echo "root:$PASS" | chpasswd
echo "🔒 Root password set."

# 2. Setup SSH Privilege Separation Directory & Host Keys
mkdir -p /run/sshd /var/run/sshd /root/.ssh /var/log/supervisor
chmod 0755 /run/sshd /var/run/sshd
chmod 0700 /root/.ssh
ssh-keygen -A

# 3. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key."
fi

# 4. Write clean sshd_config
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

# 5. Create wrapper script for ttyd
HTTP_PORT="${PORT:-8080}"
USER_NAME="${WEB_TERMINAL_USER:-root}"

cat << EOF > /usr/local/bin/start-ttyd.sh
#!/usr/bin/env bash
exec /usr/local/bin/ttyd -p ${HTTP_PORT} -c "${USER_NAME}:${PASS}" -W bash
EOF
chmod +x /usr/local/bin/start-ttyd.sh

# 6. Create static supervisord configuration
cat << 'EOF' > /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log
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
command=/usr/local/bin/start-ttyd.sh
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
echo "📡 Web Terminal listening on port: $HTTP_PORT"
echo "======================================================"

exec "$@"
