FROM ubuntu:24.04

LABEL maintainer="Muhammad Farzaneh"
LABEL description="Ubuntu 24.04 LTS VPS Container with SSH and Web Terminal for Railway"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install locales, OpenSSH server, web terminal (ttyd), and common developer/admin tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    openssh-server \
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
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd (web-based terminal)
RUN curl -sLo /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose standard SSH port (22) and web terminal default (8080)
EXPOSE 22 8080

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
