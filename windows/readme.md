# 💻 Windows to Cloud Server (Hybrid: PowerShell + WSL)

Project ini mengubah Laptop/PC Windows (dites pada **Windows 10/11**) menjadi Hybrid Server production-ready yang bisa diakses dari internet tanpa IP Public (menggunakan Cloudflare Tunnel).

**Fitur Utama:**

- **GUI Access:** Akses layar Desktop via Browser (noVNC) -> `display.domain.com`
- **Windows Admin:** Akses PowerShell via SSH (Native OpenSSH) -> `win.domain.com`
- **Linux Environment:** Environment Ubuntu lengkap di dalam Windows (WSL 2) untuk mendukung VS Code Remote SSH -> `wsl.domain.com`
- **Auto-Setup:** Script instalasi otomatis (WSL, OpenSSH, Python, Cloudflared)

<br>

## 🛠️ Tahap 1: Persiapan Windows (Wajib!)

Windows memiliki fitur sleep otomatis yang bisa mematikan server. Lakukan konfigurasi ini agar server menyala 24/7.

### 1. Power & Sleep Settings

1.  Masuk **Settings > System > Power & sleep**.
2.  Pada bagian **Sleep**, ubah "When plugged in, PC goes to sleep after" menjadi **Never**.
3.  _(Opsional)_ Pada bagian **Screen**, boleh diset 10 menit (layar mati tidak masalah, asal mesin nyala).

### 2. Execution Policy (Izin Script)

Secara default, Windows memblokir script custom. Kita harus mengizinkannya.

1.  Buka **PowerShell** sebagai **Administrator**.
2.  Ketik perintah: `Set-ExecutionPolicy RemoteSigned`
3.  Ketik **Y** lalu Enter.

### 3. Setup TightVNC (Untuk GUI)

Script installer nanti akan otomatis menginstall TightVNC, tapi kamu perlu setting password manual setelah instalasi selesai.

_(Langkah detail ada di Tahap 3 bawah)_

<br>

## ☁️ Tahap 2: Setup Cloudflare Tunnel

Kita menggunakan Cloudflare agar tidak perlu open port router.

1.  Login ke **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2.  Create Tunnel -> Pilih **Cloudflared**.
3.  Simpan **Token** (kode panjang dimulai dengan `eyJhIjoi...`).
4.  Di tab **Public Hostname**, tambahkan 3 jalur:

| Subdomain | Domain         | Service Type | URL              | Fungsi                      |
| :-------- | :------------- | :----------- | :--------------- | :-------------------------- |
| `display` | `domainmu.com` | **HTTP**     | `localhost:6080` | Akses Layar Desktop (Web)   |
| `win`     | `domainmu.com` | **SSH**      | `localhost:22`   | Akses PowerShell Windows    |
| `wsl`     | `domainmu.com` | **SSH**      | `localhost:2022` | Akses Terminal Ubuntu (SSH) |

**PENTING:** Port SSH Ubuntu adalah **2022**, bukan 22 (karena port 22 dipakai Windows). Pastikan konfigurasi Cloudflare mengarah ke `localhost:2022`.

<br>

## 🚀 Tahap 3: Instalasi di Windows

Sekarang kita setup "otak" servernya menggunakan script PowerShell otomatis.

### 1. Jalankan Installer

Buka folder `windows` di File Explorer, lalu:

1.  Klik Kanan file **`install.ps1`**.
2.  Pilih **Run with PowerShell**.
3.  Ikuti instruksi di layar (Paste Token Cloudflare saat diminta).
4.  **RESTART LAPTOP** saat instalasi selesai (Wajib untuk mengaktifkan WSL).

### 2. Setup Password VNC (Setelah Install)

Windows butuh password untuk akses layar.

1.  Klik **Start Menu**, cari **TightVNC Service - Offline Configuration**.
2.  Masuk tab **Server** -> Centang "Require authentication" -> Klik **Set Password**.
3.  Masuk tab **Access Control** -> Centang **Allow loopback connections** (PENTING agar noVNC bisa connect).
4.  Restart Service: Buka Start -> `Services` -> Cari TightVNC -> Restart.

### Apa yang dilakukan `install.ps1`?

Script ini adalah **SETUP AWAL LENGKAP** yang hanya perlu dijalankan sekali. Script akan secara otomatis:

1.  **[1/7] Enable Fitur Windows:** Mengaktifkan WSL 2 dan Virtual Machine Platform.
2.  **[2/7] Install Ubuntu:** Download & install Ubuntu WSL otomatis.
3.  **[3/7] Install OpenSSH:** Mengaktifkan SSH Server bawaan Windows (Port 22).
4.  **[4/7] Install Tools (Chocolatey):** Install `git`, `python`, `tightvnc`, `cloudflared`.
5.  **[5/7] Setup Internal Ubuntu:** Membuat script `setup_wsl_internal.sh` untuk mengubah port SSH Ubuntu ke **2022**.
6.  **[6/7] Setup noVNC:** Clone noVNC, install `websockify`, dan generate landing page.
7.  **[7/7] Generate Launcher:** Membuat file `start_server.bat` yang berisi token dan perintah startup.

### Apa yang dilakukan `update.ps1`?

Script `update.ps1` adalah untuk **UPDATE SISTEM** (bukan setup awal).

1.  **[1/3] Mematikan Server Sementara** - Kill process cloudflared, python, websockify.
2.  **[2/3] Update Windows Apps** - Jalankan `choco upgrade all` (update git, python, dll).
3.  **[3/3] Update Ubuntu WSL** - Masuk ke Ubuntu dan jalankan `apt update && apt upgrade`.
4.  **[4/3] Restart Server** - Menyalakan kembali `start_server.bat`.

<br>

## ▶️ Cara Menjalankan Server

### Startup (Normal)

Setiap kali ingin menyalakan server:

1.  Buka folder **`C:\ServerLab`**.
2.  Klik dua kali **`start_server.bat`**.
3.  Jangan tutup jendela hitam (Minimize saja).

### Startup (Dengan Update)

Jika ingin update sistem sekalian nyalakan server:

1.  Klik kanan `update.ps1` di folder project.
2.  Run with PowerShell.

---

### A. Akses Layar Desktop (Web VNC)

Buka browser di laptop/HP lain, akses:
👉 `https://display.domainmu.com`

Halaman landing akan menampilkan tombol **DISPLAY (GUI)**. Klik dan masukkan password TightVNC kamu.

### B. Akses Terminal (VS Code Remote SSH)

Untuk mengakses environment Ubuntu via VS Code Remote SSH:

1.  Pastikan Laptop Client sudah terinstall **cloudflared**.
2.  Edit file config SSH di laptop (`C:\Users\User\.ssh\config` atau `~/.ssh/config`):

```text
# --- 1. WINDOWS ADMIN (PowerShell) ---
Host win-server
    HostName win.domainmu.com
    User dev                       # Gunakan user 'dev' (User lokal yg dibuat script)
    ProxyCommand cloudflared access ssh --hostname %h

# --- 2. LINUX CODING (Ubuntu WSL) ---
Host wsl-server
    HostName wsl.domainmu.com
    User raja                      # Gunakan username Ubuntu kamu
    ProxyCommand cloudflared access ssh --hostname %h

```

3. **Connect:**

- `ssh win-server` (Password: `123` - jika pakai user dev).
- `ssh wsl-server` (Password: Password Linux kamu).

## 📝 Penjelasan Kode (Under the Hood)

### Struktur File Project

```
zero-to-server/
├── windows/
│   ├── install.ps1        (Setup awal - JALANKAN SEKALI)
│   ├── update.ps1         (Update sistem - JALANKAN BERKALA)
│   ├── readme.md          (Dokumentasi Windows)
│   └── uninstall.ps1      (Cleaner Script)

```

**File yang di-GENERATE (Di C:\ServerLab):**

- `start_server.bat` - Launcher utama server
- `setup_wsl_internal.sh` - Script konfigurasi SSH di dalam Ubuntu
- `noVNC/` - Folder web viewer

### Struktur Launcher (`start_server.bat`)

File ini digenerate otomatis berisi:

```batch
@echo off
:: 1. Start Cloudflare Tunnel
start /B cloudflared tunnel run --token [TOKEN_KAMU]

:: 2. Start Web Display (Bridge 6080 -> 5900)
start /B websockify --web C:\ServerLab\noVNC 6080 127.0.0.1:5900

:: 3. Start SSH Ubuntu (Port 2022)
wsl -d Ubuntu -- sudo /usr/sbin/sshd -D

```

**Penjelasan Port Mapping:**

- `websockify`: Menghubungkan port Web (6080) ke port VNC Windows (5900). Menggunakan `127.0.0.1` untuk menghindari blokir loopback.
- `wsl`: Menjalankan service SSH di dalam Ubuntu secara foreground.

## ⚠️ Troubleshooting

| Error                              | Penyebab                              | Solusi                                                                    |
| ---------------------------------- | ------------------------------------- | ------------------------------------------------------------------------- |
| **SSH Windows: Permission Denied** | Login pakai Akun Microsoft / PIN      | Gunakan user **`dev`** (Pass: `123`) di config SSH. Jangan pakai email.   |
| **Web VNC: "Loopback disabled"**   | Security TightVNC memblokir localhost | Buka setting TightVNC -> Access Control -> Centang **Allow Loopback**.    |
| **Ubuntu SSH: Connection Refused** | SSH Linux belum jalan / Port salah    | Pastikan script `setup_wsl_internal.sh` sudah dijalankan setelah restart. |
| **Layar Web Gelap/Blank**          | Windows dalam mode Sleep/Lock         | Gerakkan mouse di laptop server atau matikan fitur Sleep di Settings.     |
| **File `install.ps1` tidak jalan** | Execution Policy terblokir            | PowerShell Admin: `Set-ExecutionPolicy RemoteSigned` -> `Y`.              |

---

## 📊 Rangkuman Setup & File

### Script Flow

```
SETUP AWAL (SEKALI):
./install.ps1
    ├─ [1/7] Enable WSL
    ├─ [2/7] Install Ubuntu
    ├─ [3/7] Install OpenSSH Windows
    ├─ [4/7] Install Tools (Choco)
    ├─ [5/7] Setup Ubuntu SSH (Port 2022)
    ├─ [6/7] Setup noVNC
    └─ [7/7] Generate start_server.bat

NORMAL OPERATION:
./start_server.bat
    ├─ Start Cloudflare Tunnel
    ├─ Start Web Display (Websockify)
    └─ Start Ubuntu SSH Service

UPDATE BERKALA:
./update.ps1
    ├─ Kill Processes
    ├─ Update Windows Apps
    ├─ Update Ubuntu
    └─ Restart Server

```

### Port & Akses

| Komponen        | Port (Internal)  | Akses Luar           | Fungsi                     |
| --------------- | ---------------- | -------------------- | -------------------------- |
| **Ubuntu SSH**  | `localhost:2022` | `wsl.domain.com:22`  | VS Code Remote SSH (Linux) |
| **Windows SSH** | `localhost:22`   | `win.domain.com:22`  | PowerShell Admin (Windows) |
| **noVNC**       | `localhost:6080` | -                    | Web Viewer Interface       |
| **TightVNC**    | `localhost:5900` | -                    | VNC Server Asli            |
| **Cloudflare**  | -                | `display.domain.com` | GUI dari internet          |

### Environment

- **Host:** Windows 10/11
- **Guest:** Ubuntu 22.04 LTS (WSL 2)
- **VS Code:** Akses ke Ubuntu via SSH (Port 2022)
- **GUI:** Akses via noVNC + Websockify (Port 8080)
- **Internet:** Semua diexpose via Cloudflare Tunnel

### Tools yang Digunakan

- **WSL 2:** Subsystem Linux di Windows
- **Chocolatey:** Package manager Windows (untuk install tools)
- **TightVNC:** VNC Server ringan untuk Windows
- **Websockify:** Bridge TCP ke WebSocket (Python)
- **OpenSSH:** Server SSH Native Windows
- **Cloudflared:** Tunnel Client
