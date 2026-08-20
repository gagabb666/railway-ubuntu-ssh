#!/usr/bin/env bash
set -e

echo "=== Initializing Ubuntu 24.04 Desktop GUI (RDP + VNC + SSH) Container ==="

# 1. Setup root password
PASS="${SSH_PASSWORD:-M24682468*m}"
echo "root:$PASS" | chpasswd
echo "🔒 Root password set."

# 2. Setup SSH Privilege Separation Directory & Host Keys
mkdir -p /run/sshd /var/run/sshd /root/.ssh /root/.vnc /var/run/xrdp
chmod 0755 /run/sshd /var/run/sshd /var/run/xrdp
chmod 0700 /root/.ssh /root/.vnc
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

# 6. Configure XFCE4 Session for XRDP (Windows Remote Desktop)
echo "xfce4-session" > /root/.xsession
chmod +x /root/.xsession

# Configure xrdp.ini
sed -i 's/3389/3389/g' /etc/xrdp/xrdp.ini
sed -i 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

# Start XRDP daemons
echo "🖥️ Starting XRDP (Windows Remote Desktop) on port 3389..."
/usr/sbin/xrdp-sesman
/usr/sbin/xrdp

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

# Clean any existing VNC locks
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# Start TigerVNC Server on Display :1 (Port 5901)
echo "🖥️ Starting XFCE4 TigerVNC on Display :1..."
if command -v tigervncserver &>/dev/null; then
    tigervncserver :1 -geometry 1920x1080 -depth 24 -localhost yes -SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd
elif command -v vncserver &>/dev/null; then
    vncserver :1 -geometry 1920x1080 -depth 24 -localhost yes -SecurityTypes VncAuth -PasswordFile /root/.vnc/passwd
fi

# 8. Setup noVNC index redirect
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

WEB_PORT="${PORT:-8080}"
echo "======================================================"
echo "🚀 Ubuntu 24.04 Container (RDP + VNC + SSH) is online!"
echo "🔑 SSH Server listening on port: 22"
echo "🖥️ XRDP Server listening on port: 3389"
echo "🌐 Web Desktop (noVNC) listening on port: $WEB_PORT"
echo "======================================================"

# 9. Start websockify / noVNC in foreground
exec websockify --web /usr/share/novnc/ "${WEB_PORT}" localhost:5901
