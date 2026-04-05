# 💻 Windows to Cloud Server (Hybrid: PowerShell + WSL)

This project transforms a Windows Laptop/PC (tested on **Windows 10/11**) into a production-ready Hybrid Server accessible from the internet without a Public IP (using Cloudflare Tunnel).

**Key Features:**

- **GUI Access:** Desktop Screen access via Browser (noVNC) -> `display.domain.com`
- **Windows Admin:** PowerShell access via SSH (Native OpenSSH) -> `win.domain.com`
- **Linux Environment:** Full Ubuntu environment inside Windows (WSL 2) to support VS Code Remote SSH -> `wsl.domain.com`
- **Auto-Setup:** Automated installation script (WSL, OpenSSH, Python, Cloudflared)

## 🛠️ Phase 1: Windows Preparation (Mandatory!)

Windows has an auto-sleep feature that can turn off your server. Configure these settings to ensure the server stays on 24/7.

### 1. Power & Sleep Settings

1. Go to **Settings > System > Power & sleep**.
2. In the **Sleep** section, change "When plugged in, PC goes to sleep after" to **Never**.
3. _(Optional)_ In the **Screen** section, you can set it to 10 minutes (it's okay if the screen turns off, as long as the machine stays on).

### 2. Execution Policy (Script Permissions)

By default, Windows blocks custom scripts. We must allow them.

1. Open **PowerShell** as **Administrator**.
2. Type the command: `Set-ExecutionPolicy RemoteSigned`
3. Type **Y** and hit Enter.

### 3. Setup TightVNC (For GUI)

The installer script will automatically install TightVNC later, but you need to set the password manually after installation is complete.

_(Detailed steps are in Phase 3 below)_

## ☁️ Phase 2: Cloudflare Tunnel Setup

We use Cloudflare so we don't need to open router ports.

1. Login to **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2. Create Tunnel -> Select **Cloudflared**.
3. Save the **Token** (long code starting with `eyJhIjoi...`).
4. In the **Public Hostname** tab, add 3 routes:

| Subdomain | Domain           | Service Type | URL              | Function                     |
| --------- | ---------------- | ------------ | ---------------- | ---------------------------- |
| `display` | `yourdomain.com` | **HTTP**     | `localhost:6080` | Desktop Screen Access (Web)  |
| `win`     | `yourdomain.com` | **SSH**      | `localhost:22`   | Windows PowerShell Access    |
| `wsl`     | `yourdomain.com` | **SSH**      | `localhost:2022` | Ubuntu Terminal Access (SSH) |

**IMPORTANT:** The Ubuntu SSH Port is **2022**, not 22 (because port 22 is used by Windows). Ensure the Cloudflare configuration points to `localhost:2022`.

## 🚀 Phase 3: Installation on Windows

Now we set up the "brain" of the server using the automated PowerShell script.

### 1. Run the Installer

Open the `windows` folder in File Explorer, then:

1. Right-click the **`install.ps1`** file.
2. Select **Run with PowerShell**.
3. Follow the instructions on the screen (Paste the Cloudflare Token when prompted).
4. **RESTART LAPTOP** when installation is complete (Mandatory to activate WSL).

### 2. Setup VNC Password (After Install)

Windows requires a password for screen access.

1. Click **Start Menu**, search for **TightVNC Service - Offline Configuration**.
2. Go to the **Server** tab -> Check "Require authentication" -> Click **Set Password**.
3. Go to the **Access Control** tab -> Check **Allow loopback connections** (IMPORTANT for noVNC connection).
4. Restart Service: Open Start -> `Services` -> Find TightVNC -> Restart.

### What does `install.ps1` do?

This script is a **COMPLETE INITIAL SETUP** that only needs to be run once. The script will automatically:

1. **[1/7] Enable Windows Features:** Activates WSL 2 and Virtual Machine Platform.
2. **[2/7] Install Ubuntu:** Automatically downloads & installs Ubuntu WSL.
3. **[3/7] Install OpenSSH:** Activates Windows Native SSH Server (Port 22).
4. **[4/7] Install Tools (Chocolatey):** Installs `git`, `python`, `tightvnc`, `cloudflared`.
5. **[5/7] Setup Internal Ubuntu:** Creates `setup_wsl_internal.sh` script to change Ubuntu SSH port to **2022**.
6. **[6/7] Setup noVNC:** Clones noVNC, installs `websockify`, and generates the landing page.
7. **[7/7] Generate Launcher:** Creates `start_server.ps1` (and `start_server.bat` wrapper) with encrypted token loading.

### What does `update.ps1` do?

The `update.ps1` script is for **SYSTEM UPDATES** (not initial setup).

1. **[1/3] Stop Server Temporarily** - Kills cloudflared, python, websockify processes.
2. **[2/3] Update Windows Apps** - Runs `choco upgrade all` (updates git, python, etc).
3. **[3/3] Update Ubuntu WSL** - Enters Ubuntu and runs `apt update && apt upgrade`.
4. **[4/3] Restart Server** - Runs `start_server.ps1` (or fallback `start_server.bat`).

### What does `uninstall.ps1` do?

The `uninstall.ps1` script is used to **completely clean** the Windows installation.

1. Kills all server processes (cloudflared, TightVNC, websockify, SSH).
2. Removes **Ubuntu WSL** (all Linux data will be lost).
3. Deletes the `C:\ServerLab` folder.
4. _(Optional)_ Uninstall `cloudflared` and `tightvnc` applications via Chocolatey.

## ▶️ How to Run the Server

### Startup (Normal)

Whenever you want to turn on the server:

1. Open the **`C:\ServerLab`** folder.
2. Run **`start_server.ps1`** (or double-click **`start_server.bat`** wrapper).
3. Do not close the black window (Minimize only).

### Startup (With Update)

If you want to update the system and start the server simultaneously:

1. Right-click `update.ps1` in the project folder.
2. Run with PowerShell.

### Uninstall (Total Wipe)

If you want to remove all server components:

1. Right-click `uninstall.ps1`.
2. Run with PowerShell **as Administrator**.
3. Type `DELETE` when prompted for confirmation.

---

### A. Desktop Screen Access (Web VNC)

Open a browser on another laptop/phone, access:
👉 `https://display.yourdomain.com`

The landing page will show a **DISPLAY (GUI)** button. Click it and enter your TightVNC password.

### B. Terminal Access (VS Code Remote SSH)

To access the Ubuntu environment via VS Code Remote SSH:

1. Ensure the Client Laptop has **cloudflared** installed.
2. Edit the SSH config file on your laptop (`C:\Users\User\.ssh\config` or `~/.ssh/config`):

```text
# --- 1. WINDOWS ADMIN (PowerShell) ---
Host win-server
    HostName win.yourdomain.com
    User your_local_ssh_user       # Use the local user you created during install
    ProxyCommand cloudflared access ssh --hostname %h

# --- 2. LINUX CODING (Ubuntu WSL) ---
Host wsl-server
    HostName wsl.yourdomain.com
    User raja                      # Use your Ubuntu username
    ProxyCommand cloudflared access ssh --hostname %h

```

3. **Connect:**

- `ssh win-server` (Password: your strong local password).
- `ssh wsl-server` (Password: Your Linux Password).

## 📝 Code Explanation (Under the Hood)

### Project File Structure

```
zero-to-server/
├── windows/
│   ├── install.ps1        (Initial Setup - RUN ONCE)
│   ├── update.ps1         (System Update - RUN PERIODICALLY)
│   ├── readme.md          (Windows Documentation)
│   └── uninstall.ps1      (Cleaner Script)

```

**Files GENERATED (In C:\ServerLab):**

- `start_server.ps1` - Main server launcher
- `start_server.bat` - Wrapper launcher
- `setup_wsl_internal.sh` - SSH configuration script inside Ubuntu
- `noVNC/` - Web viewer folder

### Launcher Structure (`start_server.ps1`)

This file is automatically generated containing:

```powershell
# 1. Read encrypted Cloudflare token from C:\ServerLab\secrets\cloudflared.token.enc
# 2. Start Cloudflare Tunnel
Start-Process cloudflared tunnel run --token [DECRYPTED_TOKEN]

# 3. Start Web Display (Bridge 6080 -> 5900)
Start-Process python -m websockify --web C:\ServerLab\noVNC 6080 127.0.0.1:5900

# 4. Start SSH Ubuntu (Port 2022)
wsl -d Ubuntu -- sudo /usr/sbin/sshd -D

```

**Port Mapping Explanation:**

- `websockify`: Connects the Web port (6080) to the Windows VNC port (5900). Uses `127.0.0.1` to avoid loopback blocking.
- `wsl`: Runs the SSH service inside Ubuntu in the foreground.

## ⚠️ Troubleshooting

| Error                              | Cause                                   | Solution                                                              |
| ---------------------------------- | --------------------------------------- | --------------------------------------------------------------------- |
| **SSH Windows: Permission Denied** | Logged in using Microsoft Account / PIN | Use a dedicated local user created during install (strong password). Do not use email login for SSH. |
| **Web VNC: "Loopback disabled"**   | TightVNC Security blocks localhost      | Open TightVNC settings -> Access Control -> Check **Allow Loopback**. |
| **Ubuntu SSH: Connection Refused** | Linux SSH not running / Wrong Port      | Ensure script `setup_wsl_internal.sh` has run after restart.          |
| **Web Screen Dark/Blank**          | Windows is in Sleep/Lock mode           | Move the mouse on the server laptop or turn off Sleep in Settings.    |
| **File `install.ps1` not running** | Execution Policy blocked                | PowerShell Admin: `Set-ExecutionPolicy RemoteSigned` -> `Y`.          |

---

## 📊 Setup & File Summary

### Script Flow

```
INITIAL SETUP (ONCE):
./install.ps1
    ├─ [1/7] Enable WSL
    ├─ [2/7] Install Ubuntu
    ├─ [3/7] Install OpenSSH Windows
    ├─ [4/7] Install Tools (Choco)
    ├─ [5/7] Setup Ubuntu SSH (Port 2022)
    ├─ [6/7] Setup noVNC
    └─ [7/7] Generate start_server.ps1

NORMAL OPERATION:
./start_server.ps1
    ├─ Start Cloudflare Tunnel
    ├─ Start Web Display (Websockify)
    └─ Start Ubuntu SSH Service

PERIODIC UPDATE:
./update.ps1
    ├─ Kill Processes
    ├─ Update Windows Apps
    ├─ Update Ubuntu
    └─ Restart Server

```

### Ports & Access

| Component       | Port (Internal)  | External Access      | Function                   |
| --------------- | ---------------- | -------------------- | -------------------------- |
| **Ubuntu SSH**  | `localhost:2022` | `wsl.domain.com:22`  | VS Code Remote SSH (Linux) |
| **Windows SSH** | `localhost:22`   | `win.domain.com:22`  | PowerShell Admin (Windows) |
| **noVNC**       | `localhost:6080` | -                    | Web Viewer Interface       |
| **TightVNC**    | `localhost:5900` | -                    | Real VNC Server            |
| **Cloudflare**  | -                | `display.domain.com` | GUI from internet          |

### Environment

- **Host:** Windows 10/11
- **Guest:** Ubuntu 22.04 LTS (WSL 2)
- **VS Code:** Access to Ubuntu via SSH (Port 2022)
- **GUI:** Access via noVNC + Websockify (Port 8080)
- **Internet:** All exposed via Cloudflare Tunnel

### Tools Used

- **WSL 2:** Linux Subsystem on Windows
- **Chocolatey:** Windows package manager (to install tools)
- **TightVNC:** Lightweight VNC Server for Windows
- **Websockify:** Bridge TCP to WebSocket (Python)
- **OpenSSH:** Native Windows SSH Server
- **Cloudflared:** Tunnel Client
