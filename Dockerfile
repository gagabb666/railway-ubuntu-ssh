FROM ubuntu:24.04

LABEL maintainer="Muhammad Farzaneh"
LABEL description="Ubuntu 24.04 LTS Desktop GUI (XFCE4 + Google Chrome + RDP + VNC + SSH) for Railway"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV DISPLAY=:1

# Install locales, OpenSSH, XRDP, XFCE4 desktop, TigerVNC, noVNC, and developer tools
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
    firefox \
    fonts-liberation \
    xdg-utils \
    && locale-gen en_US.UTF-8 \
    && adduser xrdp ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome Stable
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./google-chrome-stable_current_amd64.deb \
    && rm -f google-chrome-stable_current_amd64.deb \
    && rm -rf /var/lib/apt/lists/*

# Configure Google Chrome to run smoothly as root
RUN sed -i 's|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable --no-sandbox --test-type %U|g' /usr/share/applications/google-chrome.desktop \
    && cp /usr/share/applications/google-chrome.desktop /etc/skel/Desktop/ 2>/dev/null || true

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose SSH (22), XRDP (3389), VNC (5901), and Web Desktop (8080)
EXPOSE 22 3389 5901 8080

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
