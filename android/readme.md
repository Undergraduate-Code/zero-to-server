# 📱 Android to Cloud Server (Termux + Cloudflare)

Project ini mengubah HP Android (dites pada **Vivo V2027 / Funtouch OS**) menjadi server Linux production-ready yang bisa diakses dari internet tanpa IP Public (menggunakan Cloudflare Tunnel).

**Fitur Utama:**

- **GUI Access:** Akses layar HP via Browser (noVNC) -> `display.domain.com`
- **Terminal Access:** Akses SSH via VS Code Remote SSH (Native SSH) -> `server.domain.com`
- **Ubuntu Environment:** Environment Ubuntu lengkap di dalam Termux (Proot) untuk mendukung VS Code Remote SSH
- **Auto-Setup:** Script instalasi otomatis (Ubuntu, Nginx, SSH, Cloudflared)

<br>

## 🛠️ Tahap 1: Persiapan Android (Wajib!)

HP Android memiliki manajemen baterai yang agresif. Lakukan konfigurasi ini agar server tidak mati sendiri (Kill Process).

### 1. Developer Options (Opsi Pengembang)

1.  Masuk **Settings > System Management > About Phone**.
2.  Ketuk **Software Version** 7x sampai muncul "You are a developer".
3.  Kembali, masuk ke **Developer Options**.
4.  Scroll ke paling bawah (Apps), cari **Background process limit**.
5.  Set ke **Standard limit** (JANGAN "No background process").

### 2. Kunci Aplikasi (Lock Recent Apps)

1.  Buka aplikasi **Termux** dan **droidVNC-NG**.
2.  Buka **Recent Apps** (Geser bawah ke tengah).
3.  Tarik ikon aplikasi ke bawah / klik menu, pilih **Lock Down** (ikon Gembok).
4.  _Tujuan: Agar saat "Clear RAM", server tidak ikut tertutup._

### 3. Izin Baterai & Autostart

1.  **Settings > Battery > Background power consumption management**.
    - Set Termux & droidVNC-NG ke **High background power usage**.
2.  **Settings > Applications and Permissions > Permission management > Autostart**.
    - Aktifkan (ON) untuk Termux & droidVNC-NG.

### 4. Setup droidVNC-NG (Untuk GUI)

1.  Download aplikasi **droidVNC-NG** di PlayStore.
2.  Buka App, berikan izin **Accessibility** & **Screen Recording**.
    - _Tips Vivo:_ Jika aksesibilitas sering mati sendiri, matikan lalu nyalakan lagi di pengaturan.
3.  Set Password VNC di dalam aplikasi.
4.  Klik **Start**.

<br>

## ☁️ Tahap 2: Setup Cloudflare Tunnel

Kita menggunakan Cloudflare agar tidak perlu open port router.

1.  Login ke **Cloudflare Zero Trust Dashboard** > **Networks** > **Tunnels**.
2.  Create Tunnel -> Pilih **Cloudflared**.
3.  Simpan **Token** (kode panjang dimulai dengan `eyJhIjoi...`).
4.  Di tab **Public Hostname**, tambahkan 3 jalur:

| Subdomain | Domain         | Service Type | URL              | Fungsi                      |
| :-------- | :------------- | :----------- | :--------------- | :-------------------------- |
| `display` | `domainmu.com` | **HTTP**     | `localhost:8080` | Akses Layar HP (Web)        |
| `server`  | `domainmu.com` | **SSH**      | `localhost:2022` | Akses Terminal Ubuntu (SSH) |
| `termux`  | `domainmu.com` | **SSH**      | `localhost:8020` | Akses Terminal Termux (SSH) |

**PENTING:** Port SSH Ubuntu adalah **2022**, bukan 8022. Pastikan konfigurasi Cloudflare mengarah ke `localhost:2022`.

<br>

## 🚀 Tahap 3: Instalasi di Termux

Sekarang kita setup "otak" servernya menggunakan script otomatis.

### 1. Install Git (Awal Saja)

Buka Termux (kosongan), ketik:

```bash
pkg update -y
pkg install git -y

```

### 2. Clone & Install

Download repository ini dan jalankan installernya:

```bash
# Clone repo
git clone https://github.com/brotherzhafif/zero-to-server.git
cd zero-to-server/android

# Jalankan installer (untuk setup awal)
chmod 777 install.sh
./install.sh
```

**ATAU** jika sudah terinstall sebelumnya dan ingin re-install/update:

```bash
# Update ke versi terbaru
chmod 777 update.sh
./update.sh
```

### Apa yang dilakukan `install.sh`?

Script ini adalah **SETUP AWAL LENGKAP** yang hanya perlu dijalankan sekali. Script akan secara otomatis:

1. **[1/7] Membersihkan** sisa proses lama (Nginx, Cloudflared, SSH, noVNC, server.sh, tunnel.log).
2. **[2/7] Update & Install Package** lengkap:
   - `git`, `wget`, `nginx`, `openssh`, `tur-repo`, `proot-distro`, `cloudflared`
3. **[3/7] Setup Ubuntu Environment** menggunakan proot-distro:
   - Download & install Ubuntu (jika belum ada)
   - Install di dalam Ubuntu: `openssh-server`, `git`, `curl`, `nano`, `net-tools`
   - Konfigurasi SSH Ubuntu pada **Port 2022**
   - Buat folder `/root/project` untuk development
4. **[4/7] Input Password Ubuntu** untuk login VS Code Remote SSH (WAJIB!)
5. **[5/7] Download noVNC** dan buat landing page custom dengan branding kamu:
   - Tanya nama web (contoh: `Raja's Lab`)
   - Tanya nama pemilik (contoh: `Raja Zhafif`)
   - Generate `index.html` dengan design hacker-style
6. **[6/7] Buat Konfigurasi Nginx** otomatis:
   - Reverse proxy dari port 8080 ke noVNC (6080)
   - Security rules: blokir akses file sensitif (`.git`, `.github`, README.md, dll)
7. **[7/7] Input Token Cloudflare** dan Generate Script `server.sh` (FINAL)

### Input yang akan diminta saat instalasi

- **Password Ubuntu**: untuk login VS Code Remote SSH (SANGAT PENTING!)
- **Nama Web**: judul halaman depan (contoh: `Raja's Lab`)
- **Nama Pemilik**: teks di intro page (contoh: `Raja Zhafif`)
- **Token Cloudflare**: kode tunnel `eyJhIjoi...` dari Cloudflare Zero Trust Dashboard

### Apa yang dilakukan `update.sh`?

Script `update.sh` adalah untuk **UPDATE SISTEM** (bukan setup awal). Script ini lebih ringan dan akan:

1. **[1/3] Mematikan Server Sementara** - Kill semua proses (cloudflared, nginx, sshd, noVNC) agar update lancar.
2. **[2/3] Update Termux Host** - Jalankan `pkg update` dan `pkg upgrade` untuk update Termux & cloudflared.
3. **[3/3] Update Ubuntu Guest** - Masuk ke Ubuntu dan jalankan `apt update`, `apt upgrade`, `apt autoremove`.
4. **[4/3] Panggil `server.sh`** - Setelah update selesai, script ini otomatis menjalankan `server.sh` untuk nyalakan ulang server.

**Gunakan ini ketika:**

- Ada update package Termux terbaru
- Ada update security Ubuntu
- Server error dan perlu re-start dengan clean

### Apa yang dilakukan `uninstall.sh`?

Script ini menghapus server Android secara bersih:

1. Mematikan semua proses (cloudflared, nginx, sshd, noVNC, proot).
2. Menghapus Ubuntu Proot-Distro dan cache.
3. Menghapus file server (`noVNC/`, `server.sh`, konfigurasi nginx, dan token Cloudflare lokal).
4. Membersihkan SSH known_hosts agar koneksi baru tidak bentrok.

---

### Script `server.sh` (PENJELASAN DETAIL)

File ini **DIBUAT OTOMATIS oleh `install.sh`** berdasarkan token Cloudflare yang kamu input. Setiap kali kamu menjalankan `./server.sh`, maka:

**[+] Reset Proses** - Kill semua proses lama agar fresh start:

```bash
pkill -f "novnc_proxy"
pkill -f "nginx"
pkill -f "cloudflared"
pkill -f "sshd"
```

**[1] Nyalakan Ubuntu SSH (Port 2022) - UTAMA untuk VS Code**

```bash
proot-distro login ubuntu -- mkdir -p /run/sshd  # Buat folder run dulu (FIX!)
nohup proot-distro login ubuntu -- /usr/sbin/sshd -D > /dev/null 2>&1 &
```

- Ini adalah **SSH UTAMA** untuk VS Code Remote SSH.
- Jalan di background tanpa blocking (`nohup`).
- Output di-direct ke `/dev/null` supaya tidak ganggu terminal.
- FIX: Membuat folder `/run/sshd` duluan biar SSH tidak crash (bad handshake).

**[2] Nyalakan Termux SSH (Port 8022) - CADANGAN**

```bash
sshd
```

- SSH untuk Termux itu sendiri.
- Hanya cadangan/maintenance jika Ubuntu SSH error.

**[3] Nyalakan noVNC & Nginx (GUI)**

```bash
nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
nginx
```

- `novnc_proxy`: Buat server VNC di port 6080, terhubung ke droidVNC-NG di port 5900.
- `nginx`: Jalankan reverse proxy di port 8080 (terhubung ke Cloudflare).

**[4] Konek Cloudflare Tunnel (Final)**

```bash
nohup cloudflared tunnel run --token $TOKEN > tunnel.log 2>&1 &
```

- Token yang kamu input pada saat instalasi disimpan di dalam `server.sh`.
- Cloudflare tunnel akan expose:
  - `display.domainmu.com` → `localhost:8080` (Nginx + noVNC)
  - `server.domainmu.com:2022` → `localhost:2022` (Ubuntu SSH)
- Output di-save ke `tunnel.log` untuk debugging jika ada masalah.

**[✅ Output di Terminal]**

```
✅ SERVER SIAP! Akses di:
🖥️  Layar HP:   https://display.brotherzhafif.my.id
📟 VS Code:    ssh server.brotherzhafif.my.id
    (User: root | Port Asli: 2022)
```

---

### Visualisasi Alur Startup

```
[A] Kamu Jalankan → ./server.sh (atau ./update.sh)
        ↓
[B] Reset Proses (Kill semua proses lama)
        ↓
[C] Nyalakan:
    ├─ Ubuntu SSH (Port 2022) → VS CODE REMOTE SSH
    ├─ Termux SSH (Port 8022) → Backup SSH
    ├─ noVNC (Port 6080) → GUI VNC Internal
    ├─ Nginx (Port 8080) → Reverse Proxy (dari Cloudflare)
    └─ Cloudflare Tunnel → Expose ke Internet
        ↓
[D] Kamu bisa akses:
    ├─ https://display.domainmu.com → GUI Layar HP
    └─ ssh root@server.domainmu.com → Terminal Ubuntu (VS Code)
```

<br>

## ▶️ Cara Menjalankan Server

### Startup Pertama Kali

```bash
cd ~/zero-to-server/android
chmod +x install.sh
./install.sh
```

Proses ini akan:

1. Setup ubuntu + SSH port 2022
2. Download noVNC & buat landing page
3. Setup Nginx reverse proxy
4. Generate `server.sh` dengan token Cloudflare kamu

**⏱️ Durasi:** ~10-15 menit (tergantung internet & ukuran file)

### Startup Setelah Itu (Normal)

Cukup jalankan `server.sh` yang sudah di-generate:

```bash
./server.sh
```

### Uninstall (Hapus Total)

Jika ingin menghapus semua komponen server:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Atau jika mau update system:

```bash
./update.sh
```

Script ini akan:

- Update Termux + Ubuntu
- Restart semua service
- Otomatis panggil `server.sh`

### Startup Backup (Tanpa Update)

Jika ingin hanya nyalakan service tanpa update:

```bash
./server.sh
```

---

### A. Akses Layar HP (Web VNC)

Buka browser di laptop/HP lain, akses:
👉 `https://display.domainmu.com/vnc.html` atau `https://display.domainmu.com`

Halaman landing akan menampilkan:

- **🚀 GUI ACCESS** - Full VNC interface
- **⚡ LITE MODE** - Lightweight VNC

### B. Akses Terminal Ubuntu (VS Code Remote SSH)

Untuk mengakses environment Ubuntu via VS Code Remote SSH:

1. Pastikan Laptop sudah terinstall **cloudflared** (Cloudflare Tunnel client).
2. Edit file config SSH di laptop (`C:\Users\User\.ssh\config` atau `~/.ssh/config` di Linux/Mac):

```text
Host vivo-ubuntu
    HostName server.domainmu.com
    User root
    Port 22
    ProxyCommand cloudflared access ssh --hostname %h
```

3. Buka VS Code, install extension **Remote - SSH**.
4. Tekan `Ctrl+Shift+P`, pilih **Remote-SSH: Connect to Host**.
5. Pilih **vivo-ubuntu** dari daftar.
6. Masukkan password Ubuntu yang kamu buat saat instalasi.

**Catatan:**

- User login: `root` (default Ubuntu proot)
- Port SSH Ubuntu: **2022** (di dalam tunnel), tapi dari luar tetap gunakan port **22**
- Folder project: `/root/project`

<br>

## 📝 Penjelasan Kode (Under the Hood)

### Struktur File Project

```
zero-to-server/
├── readme.md               (File ini - dokumentasi)
├── android/
│   ├── install.sh         (Setup awal - JALANKAN SEKALI)
│   ├── update.sh          (Update sistem - JALANKAN BERKALA)
│   ├── uninstall.sh       (Hapus server & Ubuntu Proot)
│   ├── readme.md          (Dokumentasi Android)
│   └── server.sh          (GENERATED - Startup script)
├── windows/
│   └── readme.md
└── linux/
    └── readme.md
```

**File yang di-GENERATE (Dibuat Otomatis):**

- `server.sh` - Dibuat oleh `install.sh` saat pertama kali
- `noVNC/` - Folder cloned dari GitHub
- `index.html` - Di-generate di dalam `noVNC/`

### Struktur Nginx Configuration

Konfigurasi Nginx di-generate otomatis oleh `install.sh` ke file `$PREFIX/etc/nginx/nginx.conf`:

```nginx
worker_processes 1;
events { worker_connections 1024; }
http {
    server {
        listen 8080;  # PORT: Terima dari Cloudflare

        # 1. PROXY KE noVNC (Port 6080)
        location / {
            proxy_pass http://127.0.0.1:6080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";  # WebSocket support
            proxy_set_header Host $host;
        }

        # 2. SECURITY: Blokir file/folder sensitif (diawali titik)
        # Memblokir: .git, .github, .gitignore, dll
        location ~ /\.(?!well-known) { deny all; }

        # 3. SECURITY: Blokir dokumen project yang tidak perlu publik
        # Memblokir: README.md, AUTHORS, LICENSE, package.json
        location ~ /(README.md|AUTHORS|LICENSE|package.json) { deny all; }
    }
}
```

**Penjelasan WebSocket Support:**

- `Upgrade` header: Untuk upgrade HTTP → WebSocket
- `Connection "Upgrade"`: Konfirmasi upgrade connection ke WebSocket
- Ini **PENTING** buat noVNC agar layar HP bisa streaming via WebSocket

<br>

## ⚠️ Troubleshooting

| Error                                | Penyebab                                                | Solusi                                                         |
| ------------------------------------ | ------------------------------------------------------- | -------------------------------------------------------------- |
| **SSH Connection Refused**           | Ubuntu SSH tidak jalan / Port 2022 error                | Cek: `proot-distro login ubuntu -- ps aux \| grep sshd`        |
| **VS Code tidak bisa connect**       | Password salah / cloudflared belum install di laptop    | Cek password saat install, install cloudflared di laptop       |
| **Layar Web VNC Hitam/Macet**        | droidVNC-NG tidak aktif / Accessibility permission off  | Nyalakan droidVNC-NG, cek Setting > Accessibility              |
| **Server mati sendiri**              | HP tidur (Deep Sleep) / Background limit terlalu rendah | Lakukan setup "Lock Recent Apps" & battery management          |
| **noVNC tidak loading**              | noVNC port 6080 blocked / Nginx error                   | Cek: `nginx -t` dan `pkill -f novnc_proxy && ./server.sh`      |
| **Cloudflare tunnel not connecting** | Token invalid / salah domain di Cloudflare              | Cek token di `server.sh`, pastikan Public Hostname sudah setup |
| **Ubuntu SSH: Bad Handshake**        | Folder `/run/sshd` tidak ada                            | Script sudah fix: auto create folder di `server.sh`            |

---

## 📊 Rangkuman Setup & File

### Script Flow

```
SETUP AWAL (SEKALI):
./install.sh
    ├─ [1/7] Clean up
    ├─ [2/7] Install packages
    ├─ [3/7] Install Ubuntu
    ├─ [4/7] Setup Ubuntu SSH (Port 2022)
    ├─ [5/7] Download noVNC + Landing page
    ├─ [6/7] Setup Nginx reverse proxy
    └─ [7/7] Generate server.sh ← FILE INI PALING PENTING!

NORMAL OPERATION:
./server.sh
    ├─ Reset proses
    ├─ Start Ubuntu SSH (Port 2022)
    ├─ Start Termux SSH (Port 8022)
    ├─ Start noVNC (Port 6080)
    ├─ Start Nginx (Port 8080)
    └─ Start Cloudflare Tunnel

UPDATE BERKALA:
./update.sh
    ├─ Stop semua service
    ├─ Update Termux host
    ├─ Update Ubuntu guest
    └─ Auto call ./server.sh
```

### Port & Akses

| Komponen       | Port (Internal)  | Akses Luar               | Fungsi                     |
| -------------- | ---------------- | ------------------------ | -------------------------- |
| **Ubuntu SSH** | `localhost:2022` | `server.domainmu.com:22` | VS Code Remote SSH (UTAMA) |
| **Termux SSH** | `localhost:8022` | -                        | Backup SSH Termux          |
| **noVNC**      | `localhost:6080` | -                        | VNC Server Internal        |
| **Nginx**      | `localhost:8080` | `display.domainmu.com`   | Reverse Proxy ke noVNC     |
| **Cloudflare** | -                | `display.domainmu.com`   | GUI dari internet          |
| **Cloudflare** | -                | `server.domainmu.com`    | SSH dari internet          |

### Environment

- **Host:** Termux (Android environment)
- **Guest:** Ubuntu proot-distro (Linux environment dalam Termux)
- **VS Code:** Akses ke Ubuntu via SSH (Port 2022)
- **GUI:** Akses via noVNC + Nginx (Port 8080)
- **Internet:** Semua diexpose via Cloudflare Tunnel (aman, tidak perlu open port router)

### Tools yang Digunakan

- **Termux:** Container Linux di Android
- **proot-distro:** Virtualisasi Ubuntu di dalam Termux
- **noVNC:** Web-based VNC client
- **Nginx:** Reverse proxy & web server
- **openssh-server:** SSH server (di Ubuntu)
- **cloudflared:** Cloudflare Tunnel client
- **droidVNC-NG:** VNC server untuk screen recording HP

---
