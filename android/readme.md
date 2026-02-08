# 📱 Android to Cloud Server (Termux + Cloudflare)

This project turns an Android Phone (tested on **Vivo V2027 / Funtouch OS**) into a production-ready Linux server accessible from the internet without a Public IP (using Cloudflare Tunnel).

**Key Features:**

- **GUI Access:** Screen access via Browser (noVNC) -> `display.yourdomain.com`
- **Terminal Access:** SSH access via VS Code Remote SSH (Native SSH) -> `server.yourdomain.com`
- **Ubuntu Environment:** Full Ubuntu environment inside Termux (Proot) to support VS Code Remote SSH.
- **Auto-Setup:** Automated installation script (Ubuntu, Nginx, SSH, Cloudflared).

## 🛠️ Phase 1: Android Preparation (Mandatory!)

Android phones have aggressive battery management. Configure these settings so the server doesn't turn off by itself (Process Killing).

### 1. Developer Options

1. Go to **Settings > System Management > About Phone**.
2. Tap **Software Version** 7x until "You are a developer" appears.
3. Go back, enter **Developer Options**.
4. Scroll to the bottom (Apps), find **Background process limit**.
5. Set to **Standard limit** (DO NOT select "No background process").

### 2. Lock Recent Apps

1. Open the **Termux** and **droidVNC-NG** apps.
2. Open **Recent Apps** (Swipe up to the middle).
3. Pull the app icon down / click the menu, select **Lock Down** (Padlock icon).
4. _Goal: So that when you "Clear RAM", the server does not get closed._

### 3. Battery & Autostart Permissions

1. **Settings > Battery > Background power consumption management**.

- Set Termux & droidVNC-NG to **High background power usage**.

2. **Settings > Applications and Permissions > Permission management > Autostart**.

- Turn ON for Termux & droidVNC-NG.

### 4. Setup droidVNC-NG (For GUI)

1. Download the **droidVNC-NG** app from the PlayStore.
2. Open the App, grant **Accessibility** & **Screen Recording** permissions.

- _Vivo Tip:_ If accessibility turns off often, toggle it off and then on again in settings.

3. Set the VNC Password inside the app.
4. Click **Start**.

## ☁️ Phase 2: Cloudflare Tunnel Setup

We use Cloudflare so we don't need to open router ports.

1. Login to **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2. Create Tunnel -> Select **Cloudflared**.
3. Save the **Token** (long code starting with `eyJhIjoi...`).
4. In the **Public Hostname** tab, add 3 routes:

| Subdomain | Domain           | Service Type | URL              | Function                     |
| --------- | ---------------- | ------------ | ---------------- | ---------------------------- |
| `display` | `yourdomain.com` | **HTTP**     | `localhost:8080` | Phone Screen Access (Web)    |
| `server`  | `yourdomain.com` | **SSH**      | `localhost:2022` | Ubuntu Terminal Access (SSH) |
| `termux`  | `yourdomain.com` | **SSH**      | `localhost:8020` | Termux Terminal Access (SSH) |

**IMPORTANT:** The Ubuntu SSH Port is **2022**, not 8022. Ensure the Cloudflare configuration points to `localhost:2022`.

## 🚀 Phase 3: Installation in Termux

Now we set up the "brain" of the server using the automated script.

### 1. Install Git (First Time Only)

Open Termux (fresh), type:

```bash
pkg update -y
pkg install git -y

```

### 2. Clone & Install

Download this repository and run the installer:

```bash
# Clone repo
git clone https://github.com/brotherzhafif/zero-to-server.git
cd zero-to-server/android

# Run installer (for initial setup)
chmod 777 install.sh
./install.sh

```

**OR** if previously installed and you want to re-install/update:

```bash
# Update to latest version
chmod 777 update.sh
./update.sh

```

### What does `install.sh` do?

This script is a **COMPLETE INITIAL SETUP** that only needs to be run once. The script will automatically:

1. **[1/7] Clean up** old processes (Nginx, Cloudflared, SSH, noVNC, server.sh, tunnel.log).
2. **[2/7] Update & Install Packages** complete:

- `git`, `wget`, `nginx`, `openssh`, `tur-repo`, `proot-distro`, `cloudflared`

3. **[3/7] Setup Ubuntu Environment** using proot-distro:

- Download & install Ubuntu (if not present)
- Install inside Ubuntu: `openssh-server`, `git`, `curl`, `nano`, `net-tools`
- Configure Ubuntu SSH on **Port 2022**
- Create `/root/project` folder for development

4. **[4/7] Input Ubuntu Password** for VS Code Remote SSH login (MANDATORY!)
5. **[5/7] Download noVNC** and create custom landing page with your branding:

- Ask for web name (e.g., `Raja's Lab`)
- Ask for owner name (e.g., `Raja Zhafif`)
- Generate `index.html` with hacker-style design

6. **[6/7] Create Nginx Configuration** automatically:

- Reverse proxy from port 8080 to noVNC (6080)
- Security rules: block sensitive access (`.git`, `.github`, README.md, etc.)

7. **[7/7] Input Cloudflare Token** and Generate `server.sh` Script (FINAL)

### Inputs required during installation

- **Ubuntu Password**: for VS Code Remote SSH login (VERY IMPORTANT!)
- **Web Name**: title of the front page (e.g., `Raja's Lab`)
- **Owner Name**: text on the intro page (e.g., `Raja Zhafif`)
- **Cloudflare Token**: tunnel code `eyJhIjoi...` from Cloudflare Zero Trust Dashboard

### What does `update.sh` do?

The `update.sh` script is for **SYSTEM UPDATES** (not initial setup). This script is lighter and will:

1. **[1/3] Stop Server Temporarily** - Kill all processes (cloudflared, nginx, sshd, noVNC) for a smooth update.
2. **[2/3] Update Termux Host** - Run `pkg update` and `pkg upgrade` to update Termux & cloudflared.
3. **[3/3] Update Ubuntu Guest** - Enter Ubuntu and run `apt update`, `apt upgrade`, `apt autoremove`.
4. **[4/3] Call `server.sh**`- After the update finishes, this script automatically runs`server.sh` to restart the server.

**Use this when:**

- There are new Termux package updates.
- There are Ubuntu security updates.
- Server error and needs a clean restart.

### What does `uninstall.sh` do?

This script completely removes the Android server cleanly:

1. Kills all processes (cloudflared, nginx, sshd, noVNC, proot).
2. Removes Ubuntu Proot-Distro and cache.
3. Removes server files (`noVNC/`, `server.sh`, nginx config, and local Cloudflare token).
4. Cleans SSH known_hosts so new connections don't conflict.

---

### Script `server.sh` (DETAILED EXPLANATION)

This file is **GENERATED AUTOMATICALLY by `install.sh**`based on the Cloudflare token you input. Every time you run`./server.sh`:

**[+] Reset Processes** - Kill all old processes for a fresh start:

```bash
pkill -f "novnc_proxy"
pkill -f "nginx"
pkill -f "cloudflared"
pkill -f "sshd"

```

**[1] Start Ubuntu SSH (Port 2022) - MAIN for VS Code**

```bash
proot-distro login ubuntu -- mkdir -p /run/sshd  # Create run folder first (FIX!)
nohup proot-distro login ubuntu -- /usr/sbin/sshd -D > /dev/null 2>&1 &

```

- This is the **MAIN SSH** for VS Code Remote SSH.
- Runs in the background without blocking (`nohup`).
- Output directed to `/dev/null` to keep terminal clean.
- FIX: Creates `/run/sshd` folder first so SSH doesn't crash (bad handshake).

**[2] Start Termux SSH (Port 8022) - BACKUP**

```bash
sshd

```

- SSH for Termux itself.
- Only a backup/maintenance if Ubuntu SSH errors.

**[3] Start noVNC & Nginx (GUI)**

```bash
nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
nginx

```

- `novnc_proxy`: Creates VNC server on port 6080, connected to droidVNC-NG on port 5900.
- `nginx`: Runs reverse proxy on port 8080 (connected to Cloudflare).

**[4] Connect Cloudflare Tunnel (Final)**

```bash
nohup cloudflared tunnel run --token $TOKEN > tunnel.log 2>&1 &

```

- The Token you input during installation is saved inside `server.sh`.
- Cloudflare tunnel will expose:
- `display.yourdomain.com` → `localhost:8080` (Nginx + noVNC)
- `server.yourdomain.com:2022` → `localhost:2022` (Ubuntu SSH)

- Output saved to `tunnel.log` for debugging if there are issues.

**[✅ Terminal Output]**

```
✅ SERVER READY! Access at:
🖥️  Phone Screen:   https://display.brotherzhafif.my.id
📟 VS Code:    ssh server.brotherzhafif.my.id
    (User: root | Real Port: 2022)

```

---

### Startup Flow Visualization

```
[A] You Run → ./server.sh (or ./update.sh)
        ↓
[B] Reset Processes (Kill all old processes)
        ↓
[C] Turn On:
    ├─ Ubuntu SSH (Port 2022) → VS CODE REMOTE SSH
    ├─ Termux SSH (Port 8022) → Backup SSH
    ├─ noVNC (Port 6080) → Internal GUI VNC
    ├─ Nginx (Port 8080) → Reverse Proxy (from Cloudflare)
    └─ Cloudflare Tunnel → Expose to Internet
        ↓
[D] You can access:
    ├─ https://display.yourdomain.com → Phone Screen GUI
    └─ ssh root@server.yourdomain.com → Ubuntu Terminal (VS Code)

```

## ▶️ How to Run the Server

### First Time Startup

```bash
cd ~/zero-to-server/android
chmod +x install.sh
./install.sh

```

This process will:

1. Setup ubuntu + SSH port 2022.
2. Download noVNC & create landing page.
3. Setup Nginx reverse proxy.
4. Generate `server.sh` with your Cloudflare token.

**⏱️ Duration:** ~10-15 minutes (depends on internet & file size)

### Startup After That (Normal)

Simply run the generated `server.sh`:

```bash
./server.sh

```

### Uninstall (Total Wipe)

If you want to remove all server components:

```bash
chmod +x uninstall.sh
./uninstall.sh

```

Or if you want to update system:

```bash
./update.sh

```

This script will:

- Update Termux + Ubuntu
- Restart all services
- Automatically call `server.sh`

### Backup Startup (No Update)

If you just want to turn on services without updating:

```bash
./server.sh

```

---

### A. Phone Screen Access (Web VNC)

Open a browser on another laptop/phone, access:
👉 `https://display.yourdomain.com/vnc.html` or `https://display.yourdomain.com`

The landing page will display:

- **🚀 GUI ACCESS** - Full VNC interface
- **⚡ LITE MODE** - Lightweight VNC

### B. Ubuntu Terminal Access (VS Code Remote SSH)

To access the Ubuntu environment via VS Code Remote SSH:

1. Ensure the Laptop has **cloudflared** installed (Cloudflare Tunnel client).
2. Edit the SSH config file on laptop (`C:\Users\User\.ssh\config` or `~/.ssh/config` on Linux/Mac):

```text
Host vivo-ubuntu
    HostName server.yourdomain.com
    User root
    Port 22
    ProxyCommand cloudflared access ssh --hostname %h

```

3. Open VS Code, install the **Remote - SSH** extension.
4. Press `Ctrl+Shift+P`, select **Remote-SSH: Connect to Host**.
5. Select **vivo-ubuntu** from the list.
6. Enter the Ubuntu password you created during installation.

**Notes:**

- User login: `root` (Ubuntu proot default)
- Ubuntu SSH Port: **2022** (inside tunnel), but externally use port **22**
- Project folder: `/root/project`

## 📝 Code Explanation (Under the Hood)

### Project File Structure

```
zero-to-server/
├── readme.md               (This file - documentation)
├── android/
│   ├── install.sh         (Initial Setup - RUN ONCE)
│   ├── update.sh          (System Update - RUN PERIODICALLY)
│   ├── uninstall.sh       (Remove server & Ubuntu Proot)
│   ├── readme.md          (Android Documentation)
│   └── server.sh          (GENERATED - Startup script)
├── windows/
│   └── readme.md
└── linux/
    └── readme.md

```

**Files GENERATED (Created Automatically):**

- `server.sh` - Created by `install.sh` first time.
- `noVNC/` - Folder cloned from GitHub.
- `index.html` - Generated inside `noVNC/`.

### Nginx Configuration Structure

Nginx configuration is generated automatically by `install.sh` into `$PREFIX/etc/nginx/nginx.conf`:

```nginx
worker_processes 1;
events { worker_connections 1024; }
http {
    server {
        listen 8080;  # PORT: Receive from Cloudflare

        # 1. PROXY TO noVNC (Port 6080)
        location / {
            proxy_pass http://127.0.0.1:6080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";  # WebSocket support
            proxy_set_header Host $host;
        }

        # 2. SECURITY: Block sensitive files/folders (starting with dot)
        # Blocks: .git, .github, .gitignore, etc.
        location ~ /\.(?!well-known) { deny all; }

        # 3. SECURITY: Block project documents not needed publicly
        # Blocks: README.md, AUTHORS, LICENSE, package.json
        location ~ /(README.md|AUTHORS|LICENSE|package.json) { deny all; }
    }
}

```

**WebSocket Support Explanation:**

- `Upgrade` header: To upgrade HTTP → WebSocket.
- `Connection "Upgrade"`: Confirm upgrade connection to WebSocket.
- This is **IMPORTANT** for noVNC so the phone screen can stream via WebSocket.

## ⚠️ Troubleshooting

| Error                                | Cause                                                | Solution                                                     |
| ------------------------------------ | ---------------------------------------------------- | ------------------------------------------------------------ | ---------- |
| **SSH Connection Refused**           | Ubuntu SSH not running / Port 2022 error             | Check: `proot-distro login ubuntu -- ps aux                  | grep sshd` |
| **VS Code cannot connect**           | Wrong password / cloudflared not installed on laptop | Check password from install, install cloudflared on laptop   |
| **Web VNC Screen Black/Stuck**       | droidVNC-NG inactive / Accessibility permission off  | Turn on droidVNC-NG, check Setting > Accessibility           |
| **Server dies by itself**            | Phone sleeps (Deep Sleep) / Background limit too low | Perform "Lock Recent Apps" setup & battery management        |
| **noVNC not loading**                | noVNC port 6080 blocked / Nginx error                | Check: `nginx -t` and `pkill -f novnc_proxy && ./server.sh`  |
| **Cloudflare tunnel not connecting** | Invalid token / wrong domain in Cloudflare           | Check token in `server.sh`, ensure Public Hostname is set up |
| **Ubuntu SSH: Bad Handshake**        | Folder `/run/sshd` missing                           | Script fixed: auto create folder in `server.sh`              |

---

## 📊 Setup & File Summary

### Script Flow

```
INITIAL SETUP (ONCE):
./install.sh
    ├─ [1/7] Clean up
    ├─ [2/7] Install packages
    ├─ [3/7] Install Ubuntu
    ├─ [4/7] Setup Ubuntu SSH (Port 2022)
    ├─ [5/7] Download noVNC + Landing page
    ├─ [6/7] Setup Nginx reverse proxy
    └─ [7/7] Generate server.sh ← MOST IMPORTANT FILE!

NORMAL OPERATION:
./server.sh
    ├─ Reset processes
    ├─ Start Ubuntu SSH (Port 2022)
    ├─ Start Termux SSH (Port 8022)
    ├─ Start noVNC (Port 6080)
    ├─ Start Nginx (Port 8080)
    └─ Start Cloudflare Tunnel

PERIODIC UPDATE:
./update.sh
    ├─ Stop all services
    ├─ Update Termux host
    ├─ Update Ubuntu guest
    └─ Auto call ./server.sh

```

### Port & Access

| Component      | Port (Internal)  | External Access            | Function                  |
| -------------- | ---------------- | -------------------------- | ------------------------- |
| **Ubuntu SSH** | `localhost:2022` | `server.yourdomain.com:22` | VS Code Remote SSH (MAIN) |
| **Termux SSH** | `localhost:8022` | -                          | Backup SSH Termux         |
| **noVNC**      | `localhost:6080` | -                          | Internal VNC Server       |
| **Nginx**      | `localhost:8080` | `display.yourdomain.com`   | Reverse Proxy to noVNC    |
| **Cloudflare** | -                | `display.yourdomain.com`   | GUI from internet         |
| **Cloudflare** | -                | `server.yourdomain.com`    | SSH from internet         |

### Environment

- **Host:** Termux (Android environment)
- **Guest:** Ubuntu proot-distro (Linux environment inside Termux)
- **VS Code:** Access to Ubuntu via SSH (Port 2022)
- **GUI:** Access via noVNC + Nginx (Port 8080)
- **Internet:** All exposed via Cloudflare Tunnel (secure, no need to open router ports)

### Tools Used

- **Termux:** Linux Container on Android
- **proot-distro:** Ubuntu virtualization inside Termux
- **noVNC:** Web-based VNC client
- **Nginx:** Reverse proxy & web server
- **openssh-server:** SSH server (in Ubuntu)
- **cloudflared:** Cloudflare Tunnel client
- **droidVNC-NG:** VNC server for phone screen recording
