#!/usr/bin/env bash
set -e

echo "=== Initializing Ubuntu 24.04 Desktop GUI Container ==="

# 1. Setup root password
PASS="${SSH_PASSWORD:-M24682468*m}"
echo "root:$PASS" | chpasswd
echo "🔒 Root password set."

# 2. Setup SSH & Desktop Directories
mkdir -p /run/sshd /var/run/sshd /root/.ssh /root/.vnc /var/run/xrdp /root/Desktop
chmod 0755 /run/sshd /var/run/sshd /var/run/xrdp
chmod 0700 /root/.ssh /root/.vnc
ssh-keygen -A

# 3. Setup Desktop Shortcuts (Chrome, Firefox, Falkon & Terminal)
for app in google-chrome.desktop firefox.desktop org.kde.falkon.desktop xfce4-terminal.desktop; do
    if [ -f "/usr/share/applications/$app" ]; then
        cp "/usr/share/applications/$app" /root/Desktop/
        chmod +x "/root/Desktop/$app"
    fi
done

# 4. Setup SSH Authorized Keys if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    echo "$SSH_AUTHORIZED_KEYS" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "🔑 Added SSH public key."
fi

# 5. Write clean sshd_config on Port 22
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

# 6. Configure XFCE4 Session for XRDP (Windows Remote Desktop)
echo "xfce4-session" > /root/.xsession
chmod +x /root/.xsession

# Configure xrdp.ini
sed -i 's/3389/3389/g' /etc/xrdp/xrdp.ini
sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

# 7. Configure VNC Server & XFCE4 Startup
VNC_PASS="${PASS:0:8}"
if command -v tigervncpasswd &>/dev/null; then
    echo "$VNC_PASS" | tigervncpasswd -f > /root/.vnc/passwd
elif command -v vncpasswd &>/dev/null; then
    echo "$VNC_PASS" | vncpasswd -f > /root/.vnc/passwd
fi
[ -f /root/.vnc/passwd ] && chmod 600 /root/.vnc/passwd

cat << 'EOF' > /root/.vnc/xstartup
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_DIRS=/etc/xdg
exec startxfce4
EOF
chmod +x /root/.vnc/xstartup

# 8. Setup noVNC index redirect
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

WEB_PORT="${PORT:-8080}"
echo "======================================================"
echo "🚀 Ubuntu 24.04 Container (Chrome + Firefox + Falkon + RDP + VNC + SSH) is online!"
echo "🔑 SSH Server listening on port: 22"
echo "🖥️ XRDP Server listening on port: 3389"
echo "🌐 Web Desktop (noVNC) listening on port: $WEB_PORT"
echo "======================================================"

# 9. Resilient Self-Healing Process Supervisor Loop
echo "🔄 Starting background self-healing process supervisor..."

cleanup() {
    echo "Shutting down container gracefully..."
    kill -TERM $(jobs -p) 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

while true; do
    # 1. Keep SSH Server Alive
    if ! pgrep -x sshd > /dev/null; then
        echo "🚀 (Re)starting SSH Server on port 22..."
        /usr/sbin/sshd -D -e &
    fi

    # 2. Keep XRDP Server Alive
    if ! pgrep -x xrdp > /dev/null; then
        echo "🖥️ (Re)starting XRDP Server on port 3389..."
        /usr/sbin/xrdp-sesman 2>/dev/null || true
        /usr/sbin/xrdp 2>/dev/null || true
    fi

    # 3. Keep TigerVNC Server Alive
    if ! pgrep -x Xtigervnc > /dev/null; then
        echo "🖥️ (Re)starting TigerVNC Server on Display :1..."
        rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1
        if command -v tigervncserver &>/dev/null; then
            tigervncserver :1 -geometry 1920x1080 -depth 24 -localhost yes -SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd 2>/dev/null || true
        elif command -v vncserver &>/dev/null; then
            vncserver :1 -geometry 1920x1080 -depth 24 -localhost yes -SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd 2>/dev/null || true
        fi
    fi

    # 4. Keep Web Desktop (noVNC / websockify) Alive
    if ! pgrep -f websockify > /dev/null; then
        echo "🌐 (Re)starting Web Desktop (noVNC) on port ${WEB_PORT}..."
        websockify --web /usr/share/novnc/ "${WEB_PORT}" localhost:5901 &
    fi

    sleep 5
done
