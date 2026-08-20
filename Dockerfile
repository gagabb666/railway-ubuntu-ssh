FROM ubuntu:24.04

LABEL maintainer="Muhammad Farzaneh"
LABEL description="Ubuntu 24.04 LTS Desktop GUI (XFCE4 + Chrome + Firefox + Falkon + RDP + VNC + SSH) for Railway"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV DISPLAY=:1

# Install locales, OpenSSH, XRDP, XFCE4 desktop, TigerVNC, noVNC, Falkon, and developer tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    openssh-server \
    xrdp \
    xorgxrdp \
    ca-certificates \
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    htop \
    tmux \
    zsh \
    screen \
    tree \
    jq \
    rsync \
    zip \
    unzip \
    tar \
    xz-utils \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    net-tools \
    iputils-ping \
    dnsutils \
    iproute2 \
    procps \
    lsof \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    novnc \
    websockify \
    falkon \
    fonts-liberation \
    xdg-utils \
    libdbus-glib-1-2 \
    libgtk-3-0 \
    libasound2t64 \
    libx11-xcb1 \
    && locale-gen en_US.UTF-8 \
    && adduser xrdp ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome Stable
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && rm -f google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Official Mozilla Firefox
RUN curl -sSL "https://download-installer.cdn.mozilla.net/pub/firefox/releases/154.0/linux-x86_64/en-US/firefox-154.0.tar.xz" -o /tmp/firefox.tar.xz \
    && tar -xJf /tmp/firefox.tar.xz -C /opt/ \
    && ln -sf /opt/firefox/firefox /usr/local/bin/firefox \
    && rm -f /tmp/firefox.tar.xz

# Create bulletproof Chrome wrapper to fix "Oh Snap Error Code 5" (/dev/shm limitation & sandbox in Docker)
RUN echo '#!/usr/bin/env bash' > /usr/local/bin/google-chrome-wrapper \
    && echo 'exec /opt/google/chrome/google-chrome --no-sandbox --disable-dev-shm-usage --disable-gpu --no-first-run --no-default-browser-check "$@"' >> /usr/local/bin/google-chrome-wrapper \
    && chmod +x /usr/local/bin/google-chrome-wrapper \
    && ln -sf /usr/local/bin/google-chrome-wrapper /usr/bin/google-chrome \
    && ln -sf /usr/local/bin/google-chrome-wrapper /usr/bin/google-chrome-stable \
    && sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/local/bin/google-chrome-wrapper %U|g' /usr/share/applications/google-chrome.desktop

# Create Firefox desktop entry
RUN cat << 'EOF' > /usr/share/applications/firefox.desktop
[Desktop Entry]
Version=1.0
Name=Firefox Web Browser
Comment=Browse the World Wide Web
GenericName=Web Browser
Exec=/opt/firefox/firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose SSH (22), XRDP (3389), VNC (5901), and Web Desktop (8080)
EXPOSE 22 3389 5901 8080

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
