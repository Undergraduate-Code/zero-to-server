# 🐧 Linux to Cloud Server (Native Systemd)

This project transforms a Linux Laptop/PC (Ubuntu/Debian/Mint/Kali) or VPS into a **Production Server** accessible from the internet without a Public IP. This version is the most stable as it runs natively using **Systemd Services**.

**Key Features:**

- **GUI Access:** Desktop Screen access via Browser (noVNC) -> `display.domain.com`
- **SSH Access:** Root Terminal access via SSH (Port 22) -> `linux.domain.com`
- **Auto-Start:** Server automatically starts on boot (using Systemd).
- **Auto-Setup:** Automated Bash script (Cloudflared, Python venv, Systemd).

## 🛠️ Phase 1: Linux Preparation (Mandatory!)

Before running the script, ensure your Linux machine does not "sleep" and has an active VNC Server.

### 1. Disable Sleep (Anti-Sleep)

To prevent the server from turning off when the laptop lid is closed or left idle:

1. Open Terminal.
2. Run this command to completely mask sleep features:

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

```

_(To revert: replace `mask` with `unmask`)_.

### 2. Setup VNC Server (For GUI)

The installer script requires a VNC Server running on port **5900**. We use **x11vnc** because it is lightweight and compatible with displaying the actual screen.

1. Install x11vnc:

```bash
sudo apt update
sudo apt install x11vnc -y

```

2. Create a VNC password:

```bash
x11vnc -storepasswd
# Enter password, then type 'y' to save in /home/user/.vnc/passwd

```

3. Run VNC in the background (Temporarily):

```bash
x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd -rfbport 5900 -shared &

```

> **Wayland Note:** If you are using Ubuntu 22.04+ (Wayland), it is recommended to Logout and select **"Ubuntu on Xorg"** during Login for x11vnc to run smoothly.

## ☁️ Phase 2: Cloudflare Tunnel Setup

We use Cloudflare so we don't need to open router ports.

1. Login to **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2. Create Tunnel -> Select **Cloudflared**.
3. Save the **Token** (long code starting with `eyJhIjoi...`).
4. In the **Public Hostname** tab, add 2 Routes:

| Subdomain | Domain           | Service Type | URL              | Function                    |
| --------- | ---------------- | ------------ | ---------------- | --------------------------- |
| `display` | `yourdomain.com` | **HTTP**     | `localhost:6080` | Desktop Screen Access (Web) |
| `linux`   | `yourdomain.com` | **SSH**      | `localhost:22`   | SSH Terminal Access         |

> **Info:** Linux uses the standard SSH port (**22**). Ensure the Cloudflare service type points to `localhost:22`.

## 🚀 Phase 3: Installation

This script will install all server requirements and create Systemd Services so the server starts automatically on boot.

### 1. Run the Installer

Open a terminal in the `linux` folder, then run:

```bash
# Grant execution permission
chmod +x install.sh

# Run as ROOT (Mandatory)
sudo ./install.sh

```

### 2. Input Token

The script will ask for the **Cloudflare Token**.

- Copy the token from the Cloudflare dashboard.
- Paste it into the terminal (Right Click -> Paste), then Enter.

### What does `install.sh` do?

This script is an **AUTOMATED SETUP** that performs:

1. **[1/5] Install Tools:** Installs `git`, `python3-venv`, `wget`.
2. **[2/5] Install Cloudflared:** Downloads the official Cloudflare binary for Linux (`deb`).
3. **[3/5] Setup Environment:**

- Creates the `/opt/serverlab` folder.
- Creates a Python Virtual Environment (`venv`).
- Installs `websockify` and clones `noVNC`.

4. **[4/5] Setup Systemd Service:**

- Creates `myserver-tunnel.service` (Runs automatically on boot).
- Creates `myserver-display.service` (Runs automatically on boot).

5. **[5/5] Start Services:** Starts all services immediately.

### What does `update.sh` do?

This script is for maintenance:

1. Updates the Linux system (`apt update & upgrade`).
2. Updates `cloudflared` to the latest version.
3. Restarts systemd services to apply changes.

### What does `uninstall.sh` do?

This script completely removes the Linux server setup:

1. Stops and disables systemd services (`myserver-tunnel`, `myserver-display`).
2. Removes service files in `/etc/systemd/system/` then runs `daemon-reload`.
3. Removes the `/opt/serverlab` folder and `/etc/cloudflared` config.
4. _(Optional)_ Uninstalls the `cloudflared` package via `apt remove`.

## ▶️ How to Run the Server

### Automatic (Systemd)

Since we are using Systemd, the server will **ALWAYS BE ON** whenever the laptop/PC is turned on. You do not need to run the script manually.

### Manual Control

If you want to turn the server off/on manually:

```bash
# Check Status
sudo systemctl status myserver-tunnel
sudo systemctl status myserver-display

# Stop Server
sudo systemctl stop myserver-tunnel myserver-display

# Start Server
sudo systemctl start myserver-tunnel myserver-display

```

### Uninstall (Total Wipe)

If you want to remove all server components:

```bash
sudo ./uninstall.sh

```

## 🖥️ Access Method (Client Side)

### A. Screen Access (Web VNC)

Open a browser on another Phone/Laptop, access:
👉 `https://display.yourdomain.com`

- Click **Display**.
- Enter the Password you created during the `x11vnc` setup earlier.

### B. Terminal Access (VS Code Remote SSH)

1. Ensure the Client Laptop has **cloudflared** installed.
2. Edit SSH config (`~/.ssh/config`):

```text
Host my-linux
    HostName linux.yourdomain.com
    User your_linux_username   # Example: root / ubuntu / kali
    Port 22
    ProxyCommand cloudflared access ssh --hostname %h

```

3. **Connect:**

- `ssh my-linux`
- Enter your Linux user password.

## 📝 Code Explanation (Under the Hood)

### Project File Structure

```
zero-to-server/
├── linux/
│   ├── install.sh         (Initial Setup & Systemd Generator)
│   ├── update.sh          (System & Cloudflared Update)
│   ├── uninstall.sh       (Remove Service & Files)
│   └── readme.md          (Documentation)

```

**Installation Location (Inside Linux):**

- `/opt/serverlab/` : Main project folder (noVNC, venv).
- `/etc/systemd/system/myserver-*.service` : Auto-start configuration files.
- `/usr/bin/cloudflared` : Tunnel Application.

### Systemd Service Structure

We create 2 "robots" to guard the server:

1. **`myserver-tunnel.service`**

- Task: Maintains Cloudflare Tunnel connection so it doesn't drop.
- Command: `cloudflared tunnel run --token [TOKEN]`
- Restart: `Always` (If it crashes, it restarts immediately).

2. **`myserver-display.service`**

- Task: Runs the Web-to-VNC bridge.
- Command: `python3 websockify --web noVNC 6080 localhost:5900`
- Restart: `Always`.

## ⚠️ Troubleshooting

| Error                        | Cause                 | Solution                                                                                                       |
| ---------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Black / Blank Screen**     | Wayland Protocol      | Logout of Ubuntu, click the gear ⚙️ in the bottom right corner, select **"Ubuntu on Xorg"**, then login again. |
| **"Failed to bind to port"** | Port 5900/6080 in use | Check `sudo netstat -tulpn`. Kill other services using those ports.                                            |
| **SSH Permission Denied**    | Root login disabled   | Edit `/etc/ssh/sshd_config`, set `PermitRootLogin yes`, then `sudo service ssh restart`.                       |
| **Cloudflare Error**         | Wrong / Expired Token | Uninstall (`sudo ./uninstall.sh`) then Reinstall with a new token.                                             |

---

## 📊 Setup & File Summary

### Script Flow

```
INITIAL SETUP (ONCE):
./install.sh
    ├─ [1/5] Install Tools
    ├─ [2/5] Install Cloudflared
    ├─ [3/5] Setup Environment
    ├─ [4/5] Create Systemd Services
    └─ [5/5] Start All Services

NORMAL OPERATION (AUTO):
Systemd (Background Service)
    ├─ myserver-tunnel.service (Maintain Connection)
    └─ myserver-display.service (Maintain GUI)

MAINTENANCE:
./update.sh
    ├─ Update System
    ├─ Update Cloudflared
    └─ Restart Services

```

### Port Mapping Architecture

```
[INTERNET / CLIENT]
       ⬇
[CLOUDFLARE TUNNEL]
       ⬇
[LINUX SERVER]
       ├─ display.domain ➡ Port 80/443 ➡ Localhost:6080 (Websockify) ➡ Localhost:5900 (x11vnc)
       └─ linux.domain   ➡ Port 22     ➡ Localhost:22   (Native OpenSSH)

```

### Environment

- **Host:** Ubuntu / Debian / Kali Linux / Mint.
- **Service Manager:** Systemd (Standard Linux).
- **VNC Server:** x11vnc (Recommended) or Tigervnc.
- **SSH Server:** OpenSSH Server.

### Tools Used

- **Systemd:** Native Linux service manager. We use it so the server starts automatically on boot (Auto-Start) and restarts if it crashes.
- **x11vnc:** VNC Server for X Window systems (X11). Chosen because it can display the **Physical Screen** that is currently active, rather than creating a new virtual session.
- **noVNC:** HTML5 VNC Client. Allows remote desktop access directly from a browser.
- **Websockify:** A bridge that translates TCP connections (VNC) into WebSockets so they can be read by a browser.
- **Cloudflared:** Official Cloudflare daemon to create encrypted tunnels without opening router ports.
- **OpenSSH Server:** Industry standard for secure remote terminal access.
- **Python venv:** Virtual Environment to isolate this project's Python library installation from the main system.
