# 📱 Vivo Server: Android to Cloud Server (Termux + Cloudflare)

Project ini mengubah HP Android (dites pada **Vivo V2027 / Funtouch OS**) menjadi server Linux production-ready yang bisa diakses dari internet tanpa IP Public (menggunakan Cloudflare Tunnel).

**Fitur Utama:**

- **GUI Access:** Akses layar HP via Browser (noVNC) -> `display.domain.com`
- **Terminal Access:** Akses SSH via VS Code/CMD (Native SSH) -> `server.domain.com`
- **Auto-Setup:** Script instalasi otomatis (Nginx, SSH, Cloudflared).

<br>

## 🛠️ Tahap 1: Persiapan Android (Wajib!)

HP Vivo/Funtouch OS memiliki manajemen baterai yang agresif. Lakukan konfigurasi ini agar server tidak mati sendiri (Kill Process).

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
4.  Di tab **Public Hostname**, tambahkan 2 jalur:

| Subdomain | Domain         | Service Type | URL              | Fungsi               |
| :-------- | :------------- | :----------- | :--------------- | :------------------- |
| `display` | `domainmu.com` | **HTTP**     | `localhost:8080` | Akses Layar HP (Web) |
| `server`  | `domainmu.com` | **SSH**      | `localhost:8022` | Akses Terminal (SSH) |

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

# Jalankan installer
chmod 777 install.sh
./install.sh

```

### Apa yang dilakukan `install.sh`?

Script ini akan secara otomatis:

1. **Membersihkan** sisa proses lama (Nginx, Cloudflared, dll).
2. **Menginstall** paket: `nginx`, `openssh`, `cloudflared`, `tur-repo`.
3. **Mengunduh noVNC** untuk antarmuka web dan membuat landing page custom (ganti Directory Listing) sesuai nama web/owner yang kamu input.
4. **Setup SSH Password** untuk akses terminal.
5. **Konfigurasi Nginx** otomatis (proxy ke noVNC).
6. **Input Token Cloudflare** dan pembuatan script `server.sh`.

### Input yang akan diminta saat instalasi

- **Password SSH**: untuk login terminal.
- **Nama Web**: judul halaman depan noVNC (contoh: `Raja's Server Lab`).
- **Nama Pemilik/Lab**: teks pada intro (contoh: `Raja Zhafif`).
- **Token Cloudflare**: kode tunnel `eyJhIjoi...`.

### 3. Update Sistem & Cloudflared

Setelah server berjalan beberapa waktu, Anda mungkin perlu melakukan update. Gunakan script `update.sh`:

```bash
chmod 777 update.sh
./update.sh

```

### Apa yang dilakukan `update.sh`?

Script ini akan:

1. **Matikan server** sementara (Cloudflared, Nginx, SSH).
2. **Update sistem** Termux (`pkg update` & `pkg upgrade`).
3. **Update Cloudflared** ke versi terbaru (jika dipasang via `pkg`).
4. **Tampilkan versi** Cloudflared yang aktif.
5. **Memberikan pesan** untuk memulai kembali server dengan `./server.sh`.
6. **Membuat Config Nginx** reverse proxy (Port 8080 -> 6080).
7. **Meminta Token & Password** dari user.

<br>

## 💻 Tahap 4: Cara Akses

### A. Akses Layar HP (Web VNC)

Buka browser di laptop/HP lain, akses:
👉 `https://display.domainmu.com/vnc.html`

### B. Akses Terminal (Native SSH)

Agar bisa akses via VS Code atau CMD Laptop, perlu setup **Client Side** sekali saja.

1. Pastikan Laptop sudah terinstall **cloudflared**.
2. Edit file config SSH di laptop (`C:\Users\User\.ssh\config`):

```text
Host vivo
    HostName server.domainmu.com
    User u0_a123  <-- Ganti dengan username termux (cek pakai command 'whoami')
    Port 22
    ProxyCommand C:\Windows\System32\cloudflared.exe access ssh --hostname %h

```

3. Konek dari terminal laptop:

```bash
ssh vivo

```

_(Masukkan password yang kamu buat saat instalasi)_.

<br>

## 📝 Penjelasan Kode (Under the Hood)

### Struktur `nginx.conf`

Kita menggunakan Nginx sebagai "Satpam" (Reverse Proxy) yang meneruskan trafik dari Cloudflare (8080) ke noVNC (6080), dengan fitur keamanan.

```nginx
server {
    listen 8080; # Pintu Masuk dari Cloudflare

    # 1. Proxy ke noVNC (Port 6080)
    location / {
        proxy_pass http://127.0.0.1:6080/; # Diteruskan ke noVNC
        # ... (Header settings untuk WebSocket)
    }

    # 2. SECURITY: Blokir akses ke file/folder sensitif (titik di depan)
    # Ini akan memblokir .git, .github, .gitignore, dll.
    location ~ /\.(?!well-known) {
        deny all;
    }

    # 3. SECURITY: Blokir file dokumen project yang gak perlu dilihat umum
    location ~ /(README.md|AUTHORS|LICENSE|package.json|mandatory.json) {
        deny all;
    }
}

```

**Penjelasan Security Rules:**

- **Rule 2:** Blokir akses ke semua file/folder yang diawali dengan titik (`.`), seperti `.git`, `.github`, `.gitignore`. Exception: `.well-known` (untuk SSL verification).
- **Rule 3:** Blokir akses ke file dokumentasi sensitif yang tidak perlu dilihat publik.

### Script Utama `server.sh`

Script ini dijalankan setiap kali server mau dinyalakan (`./server.sh`).

```bash
# Mencegah HP tidur (Deep Sleep)
termux-wake-lock

# Menyalakan SSH Server (Port 8022)
sshd

# Menyalakan noVNC (Background process)
nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &

# Menyalakan Nginx & Cloudflare Tunnel
nginx
nohup cloudflared tunnel run --token $TOKEN &

```

<br>

## ⚠️ Troubleshooting

- **Layar Web VNC Macet/Hitam:** Cek izin aksesibilitas `droidVNC-NG` di pengaturan HP, matikan lalu nyalakan lagi.
- **SSH Connection Refused:** Pastikan konfigurasi Public Hostname di Cloudflare mengarah ke `localhost:8022` dengan tipe service **SSH**.
- **Server Mati Sendiri:** Pastikan sudah melakukan "Lock Recent Apps" dan setting baterai "High Usage".
