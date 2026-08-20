# 🚀 Ubuntu 24.04 LTS VPS on Railway (SSH & Web Terminal)

A production-ready Ubuntu 24.04 LTS container tailored for Railway, giving you a cloud Linux environment accessible via **both native SSH** and an interactive **Browser Web Terminal**.

---

## ✨ Features

- **Ubuntu 24.04 LTS (Noble Numbat)** base with full root access.
- **Dual Connection Modes**:
  - 🔑 **Direct SSH (Port 22)**: Connect with any standard SSH client (Termius, PuTTY, OpenSSH, VS Code Remote-SSH) via Railway TCP Proxy.
  - 🌐 **Web Terminal (Port `$PORT`)**: Access an interactive Bash terminal directly in your web browser over your secure Railway HTTPS domain (`https://your-service.up.railway.app`).
- **Pre-installed Developer Tools**:
  - `git`, `curl`, `wget`, `nano`, `vim`, `htop`, `tmux`, `zsh`, `screen`, `tree`, `jq`, `rsync`, `build-essential`
  - `python3`, `python3-pip`, `python3-venv`
  - `nodejs`, `npm`
  - `net-tools`, `iproute2`, `dnsutils`, `ping`, `procps`, `lsof`
- **Configurable Credentials**: Set your custom root password or SSH public key via Railway environment variables.

---

## 🛠️ Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `SSH_PASSWORD` | `UbuntuRailway2026!` | Root password for SSH and Web Terminal access. |
| `SSH_AUTHORIZED_KEYS` | *(empty)* | Optional SSH public key (e.g. `ssh-ed25519 AAAAC...`) for key-based login. |
| `WEB_TERMINAL_USER` | `root` | Username required when logging into the Web Terminal. |
| `WEB_TERMINAL_PASSWORD`| *(matches `SSH_PASSWORD`)* | Password for Web Terminal (defaults to `SSH_PASSWORD`). |

---

## 🚀 How to Deploy on Railway

### Step 1: Deploy from GitHub
1. Push this repository to your GitHub account (e.g., `https://github.com/sharky-01/railway-ubuntu-ssh`).
2. Go to your [Railway Dashboard](https://railway.app/).
3. Click **New Project** → **Deploy from GitHub repo** → Select this repository.

### Step 2: Set Environment Variables (Optional but Recommended)
1. In your Railway service dashboard, go to the **Variables** tab.
2. Add:
   - `SSH_PASSWORD` = `YourCustomStrongPassword123!`

### Step 3: Enable Direct SSH (Railway TCP Proxy)
1. Go to **Settings** → **Networking** → Click **Add TCP Proxy**.
2. Set the target port to: **`22`**.
3. Railway will assign a public domain and port (e.g. `junction.proxy.rlwy.net:18492`).

### Step 4: Add Persistent Storage (Optional)
To keep your files and configurations across restarts:
1. Go to the **Volumes** tab in your service.
2. Click **Add Volume** and mount it to `/root` or `/home`.

---

## 🔌 How to Connect

### 1. Connecting via Native SSH
Run this command from your local terminal (or enter details into Termius / PuTTY / VS Code):
```bash
ssh root@<proxy-domain>.proxy.rlwy.net -p <proxy-port>
```
*Example:*
```bash
ssh root@junction.proxy.rlwy.net -p 18492
```
Enter your `SSH_PASSWORD` when prompted.

---

### 2. Connecting via Web Browser Terminal
1. Open your public Railway URL (e.g. `https://your-service.up.railway.app`).
2. When prompted for basic auth:
   - **Username**: `root` (or `$WEB_TERMINAL_USER`)
   - **Password**: Your `SSH_PASSWORD`
3. Enjoy your full interactive bash shell in the browser!
