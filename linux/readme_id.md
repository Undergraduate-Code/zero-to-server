# 🐧 Linux to Cloud Server (Native Systemd)

Project ini mengubah Laptop/PC Linux (Ubuntu/Debian/Mint/Kali) atau VPS menjadi **Production Server** yang bisa diakses dari internet tanpa IP Public. Versi ini paling stabil karena berjalan secara native menggunakan **Systemd Service**.

**Fitur Utama:**

- **GUI Access:** Akses layar Desktop via Browser (noVNC) -> `display.domain.com`
- **SSH Access:** Akses Terminal Root via SSH (Port 22) -> `linux.domain.com`
- **Auto-Start:** Server otomatis menyala saat booting (menggunakan Systemd).
- **Auto-Setup:** Script Bash otomatis (Cloudflared, Python venv, Systemd).

<br>

## 🛠️ Tahap 1: Persiapan Linux (Wajib!)

Sebelum menjalankan script, pastikan Linux kamu tidak "tertidur" dan memiliki VNC Server yang aktif.

### 1. Matikan Sleep (Anti-Sleep)

Agar server tidak mati saat laptop ditutup atau didiamkan:

1.  Buka Terminal.
2.  Jalankan perintah ini untuk mematikan fitur sleep secara total:
    ```bash
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    ```
    _(Untuk mengembalikan: ganti `mask` dengan `unmask`)_.

### 2. Setup VNC Server (Untuk GUI)

Script installer nanti membutuhkan VNC Server yang berjalan di port **5900**. Kita gunakan **x11vnc** karena paling ringan dan kompatibel untuk menampilkan layar asli.

1.  Install x11vnc:
    ```bash
    sudo apt update
    sudo apt install x11vnc -y
    ```
2.  Buat password VNC:
    ```bash
    x11vnc -storepasswd
    # Masukkan password, lalu pilih 'y' untuk simpan di /home/user/.vnc/passwd
    ```
3.  Jalankan VNC di background (Sementara):
    ```bash
    x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth ~/.vnc/passwd -rfbport 5900 -shared &
    ```

> **Catatan Wayland:** Jika kamu pakai Ubuntu 22.04+ (Wayland), disarankan Logout dan pilih **"Ubuntu on Xorg"** saat Login agar x11vnc berjalan lancar.

<br>

## ☁️ Tahap 2: Setup Cloudflare Tunnel

Kita menggunakan Cloudflare agar tidak perlu open port router.

1.  Login ke **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2.  Create Tunnel -> Pilih **Cloudflared**.
3.  Simpan **Token** (kode panjang dimulai dengan `eyJhIjoi...`).
4.  Di tab **Public Hostname**, tambahkan 2 Jalur:

| Subdomain | Domain         | Service Type | URL              | Fungsi                    |
| :-------- | :------------- | :----------- | :--------------- | :------------------------ |
| `display` | `domainmu.com` | **HTTP**     | `localhost:6080` | Akses Layar Desktop (Web) |
| `linux`   | `domainmu.com` | **SSH**      | `localhost:22`   | Akses Terminal SSH        |

> **Info:** Linux menggunakan port SSH standar (**22**). Pastikan service type di Cloudflare mengarah ke `localhost:22`.

<br>

## 🚀 Tahap 3: Instalasi

Script ini akan menginstall semua kebutuhan server dan membuat Service Systemd agar server menyala otomatis saat booting.

### 1. Jalankan Installer

Buka terminal di folder `linux`, lalu jalankan:

```bash
# Berikan izin eksekusi
chmod +x install.sh

# Jalankan sebagai ROOT (Wajib)
sudo ./install.sh

```

### 2. Input Token

Script akan meminta **Token Cloudflare**.

- Copy token dari dashboard Cloudflare.
- Paste di terminal (Klik Kanan -> Paste), lalu Enter.

### Apa yang dilakukan `install.sh`?

Script ini adalah **SETUP OTOMATIS** yang melakukan:

1. **[1/5] Install Tools:** Menginstall `git`, `python3-venv`, `wget`.
2. **[2/5] Install Cloudflared:** Download binary resmi Cloudflare untuk Linux (`deb`).
3. **[3/5] Setup Environment:**

- Membuat folder `/opt/serverlab`.
- Membuat Python Virtual Environment (`venv`).
- Install `websockify` dan clone `noVNC`.

4. **[4/5] Setup Systemd Service:**

- Membuat `myserver-tunnel.service` (Jalan otomatis saat boot).
- Membuat `myserver-display.service` (Jalan otomatis saat boot).

5. **[5/5] Start Services:** Menyalakan semua layanan detik itu juga.

### Apa yang dilakukan `update.sh`?

Script ini untuk maintenance:

1. Update sistem Linux (`apt update & upgrade`).
2. Update `cloudflared` ke versi terbaru.
3. Restart service systemd agar perubahan diterapkan.

### Apa yang dilakukan `uninstall.sh`?

Script ini menghapus server Linux secara bersih:

1. Stop dan disable service systemd (`myserver-tunnel`, `myserver-display`).
2. Hapus file service di `/etc/systemd/system/` lalu `daemon-reload`.
3. Hapus folder `/opt/serverlab` dan config `/etc/cloudflared`.
4. _(Opsional)_ Uninstall paket `cloudflared` via `apt remove`.

## ▶️ Cara Menjalankan Server

### Otomatis (Systemd)

Karena kita menggunakan Systemd, server akan **SELALU NYALA** setiap kali laptop/PC dinyalakan. Kamu tidak perlu menjalankan script manual.

### Kontrol Manual

Jika kamu ingin mematikan/menyalakan server secara manual:

```bash
# Cek Status
sudo systemctl status myserver-tunnel
sudo systemctl status myserver-display

# Matikan Server
sudo systemctl stop myserver-tunnel myserver-display

# Nyalakan Server
sudo systemctl start myserver-tunnel myserver-display

```

### Uninstall (Hapus Total)

Jika ingin menghapus semua komponen server:

```bash
sudo ./uninstall.sh
```

## 🖥️ Cara Akses (Client Side)

### A. Akses Layar (Web VNC)

Buka browser di HP/Laptop lain, akses:
👉 `https://display.domainmu.com`

- Klik **Display**.
- Masukkan Password yang kamu buat saat setup `x11vnc` tadi.

### B. Akses Terminal (VS Code Remote SSH)

1. Pastikan Laptop Client sudah terinstall **cloudflared**.
2. Edit config SSH (`~/.ssh/config`):

```text
Host my-linux
    HostName linux.domainmu.com
    User nama_user_linuxmu   # Contoh: root / ubuntu / kali
    Port 22
    ProxyCommand cloudflared access ssh --hostname %h

```

3. **Connect:**

- `ssh my-linux`
- Masukkan password user Linux kamu.

## 📝 Penjelasan Kode (Under the Hood)

### Struktur File Project

```
zero-to-server/
├── linux/
│   ├── install.sh         (Setup awal & Systemd Generator)
│   ├── update.sh          (Update System & Cloudflared)
│   ├── uninstall.sh       (Hapus Service & File)
│   └── readme.md          (Dokumentasi)

```

**Lokasi Instalasi (Di dalam Linux):**

- `/opt/serverlab/` : Folder utama project (noVNC, venv).
- `/etc/systemd/system/myserver-*.service` : File konfigurasi auto-start.
- `/usr/bin/cloudflared` : Aplikasi Tunnel.

### Struktur Systemd Service

Kami membuat 2 "robot" penjaga server:

1. **`myserver-tunnel.service`**

- Tugas: Menjaga koneksi Cloudflare Tunnel agar tidak putus.
- Command: `cloudflared tunnel run --token [TOKEN]`
- Restart: `Always` (Jika crash, langsung nyala lagi).

2. **`myserver-display.service`**

- Tugas: Menjalankan jembatan Web-ke-VNC.
- Command: `python3 websockify --web noVNC 6080 localhost:5900`
- Restart: `Always`.

## ⚠️ Troubleshooting

| Error                        | Penyebab                | Solusi                                                                                         |
| ---------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------- |
| **Layar Hitam / Blank**      | Wayland Protocol        | Logout Ubuntu, klik gear ⚙️ di pojok kanan bawah, pilih **"Ubuntu on Xorg"**, lalu login lagi. |
| **"Failed to bind to port"** | Port 5900/6080 terpakai | Cek `sudo netstat -tulpn`. Matikan service lain yg memakai port tersebut.                      |
| **SSH Permission Denied**    | Login root dimatikan    | Edit `/etc/ssh/sshd_config`, set `PermitRootLogin yes`, lalu `sudo service ssh restart`.       |
| **Cloudflare Error**         | Token salah / Expired   | Uninstall (`sudo ./uninstall.sh`) lalu Install ulang dengan token baru.                        |

---

## 📊 Rangkuman Setup & File

### Script Flow

```
SETUP AWAL (SEKALI):
./install.sh
    ├─ [1/5] Install Tools
    ├─ [2/5] Install Cloudflared
    ├─ [3/5] Setup Environment
    ├─ [4/5] Create Systemd Services
    └─ [5/5] Start All Services

NORMAL OPERATION (AUTO):
Systemd (Background Service)
    ├─ myserver-tunnel.service (Jaga Koneksi)
    └─ myserver-display.service (Jaga GUI)

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
- **VNC Server:** x11vnc (Disarankan) atau Tigervnc.
- **SSH Server:** OpenSSH Server.

### Tools yang Digunakan

- **Systemd:** Service manager bawaan Linux. Kita menggunakannya agar server otomatis nyala saat booting (Auto-Start) dan restart jika crash.
- **x11vnc:** Server VNC untuk sistem X Window (X11). Dipilih karena bisa menampilkan **Layar Fisik** yang sedang aktif, bukan membuat sesi virtual baru.
- **noVNC:** HTML5 VNC Client. Memungkinkan akses remote desktop langsung dari browser.
- **Websockify:** Jembatan (Bridge) yang menerjemahkan koneksi TCP (VNC) menjadi WebSocket agar bisa dibaca browser.
- **Cloudflared:** Daemon resmi Cloudflare untuk membuat tunnel terenkripsi tanpa membuka port router.
- **OpenSSH Server:** Standar industri untuk akses remote terminal yang aman.
- **Python venv:** Virtual Environment untuk mengisolasi instalasi library Python project ini dari sistem utama.
