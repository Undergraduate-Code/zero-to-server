# 🌐 Zero to Server
> **Turn any device into a accessible Cloud Server (Android, Windows, Linux).**

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Status](https://img.shields.io/badge/Status-Active_Development-green)
![Author](https://img.shields.io/badge/Maintained_by-Student-orange)

## 📖 About The Project

Project ini bertujuan untuk mendemokratisasi akses server. Kami percaya bahwa setiap orang bisa memiliki server sendiri tanpa harus menyewa VPS mahal, cukup dengan memanfaatkan device yang sudah dimiliki (HP Android bekas, Laptop Windows, atau Mini PC Linux).

Inti dari project ini adalah mengubah device lokal menjadi server yang bisa diakses dari mana saja via internet dengan aman dan mudah.

### 🛠️ The Tech Stack (Core)
Kami menggunakan kombinasi teknologi *open-source* yang powerful untuk menembus batasan jaringan (CGNAT) tanpa perlu IP Public statis:

* **☁️ Cloudflare Tunnel:** Mengekspos server lokal ke internet secara aman (tanpa Open Port di router).
* **💻 SSH (Secure Shell):** Akses penuh ke terminal server untuk coding, remote config, dan manajemen file (Backend).
* **🖥️ VNC (Virtual Network Computing):** Akses visual/layar desktop dari device server via browser (Frontend/GUI).
* **🔧 Nginx:** Reverse proxy untuk mengatur lalu lintas antara Cloudflare, VNC, dan Localhost.

<br>

## ⚠️ Disclaimer (Penting!)

> **Project ini dibuat untuk tujuan EDUKASI dan PEMBELAJARAN.**

Project ini dikembangkan oleh mahasiswa sebagai sarana riset infrastruktur jaringan. Harap perhatikan hal berikut:
1.  **Keamanan:** Konfigurasi keamanan di sini adalah *standard practice* untuk hobi/dev, bukan *enterprise-grade*. Jangan gunakan untuk menyimpan data perbankan, *production database* krusial, atau rahasia negara. **Use at your own risk.**
2.  **Stabilitas:** Performa server sangat bergantung pada spesifikasi device dan koneksi internet rumah kamu.
3.  **Riset Lanjutan:** Pengguna sangat disarankan untuk meriset lebih lanjut mengenai *firewall*, *SSH Key hardening*, dan manajemen *token* agar server lebih aman.

<br>

## 🗺️ Supported Platforms & Status

Pilih sistem operasi device yang ingin kamu jadikan server:

### 1. 🤖 Android Server (Termux)
> **Status:** ✅ **FIRST RELEASE (Stable)**

Mengubah HP Android menjadi Linux Server mini yang powerful. Sangat hemat daya (bisa pakai HP layar pecah sekalipun).
* **Base:** Termux & Proot-Distro.
* **Features:** Akses layar HP via Browser (noVNC), Full Terminal SSH via VS Code, Auto-Install Script.
* **Cocok untuk:** Hosting bot WA/Discord, Web Server ringan, Belajar Linux.

👉 **[Buka Panduan Android Setup](./android/README.md)**

### 2. 🪟 Windows Server
> **Status:** 🚧 **In Development (Coming Soon)**

Memanfaatkan laptop/PC Windows sebagai server tanpa perlu dual-boot.
* **Base:** PowerShell / WSL (Windows Subsystem for Linux).
* **Features:** Remote Desktop via Browser, PowerShell SSH access.
* **Cocok untuk:** Server Game (Minecraft/SAMP), Media Server (Plex), Heavy processing.

👉 *Link akan tersedia segera...*

### 3. 🐧 Linux Server (Ubuntu/Debian)
> **Status:** 🚧 **In Development (Coming Soon)**

Setup klasik untuk device seperti Raspberry Pi, STB Bekas, atau Mini PC.
* **Base:** Systemd Services.
* **Features:** Full Automation, Docker Support, Hardened Security.
* **Cocok untuk:** Home Lab, Docker Container, Home Assistant.

👉 *Link akan tersedia segera...*

<br>

## 🔐 Architecture Overview

Secara umum, beginilah cara server kamu bekerja di semua platform:

```mermaid
graph LR
    User[User di Internet] -- HTTPS/SSH --> CF[Cloudflare Edge]
    CF -- Tunnel (Encrypted) --> LocalDevice[Device Kamu (Android/PC)]
    LocalDevice --> Nginx[Nginx Proxy]
    Nginx -- Port 8080 --> VNC[Visual GUI (Layar)]
    Nginx -- Port 22/8022 --> SSH[Terminal SSH]

```

1. **User** mengakses domain (misal: `server.namakamu.com`).
2. **Cloudflare** menerima request dan meneruskannya lewat jalur khusus (Tunnel) ke device kamu di rumah.
3. **Device kamu** menerima paket tersebut tanpa perlu setting Router/Modem.
4. **Nginx** di dalam device memilah: "Mau lihat layar? Ke VNC. Mau coding? Ke SSH."

<br>

## 🤝 Contributing

Karena project ini berbasis komunitas dan pembelajaran, kontribusi sangat diharapkan! Jika kamu punya ide untuk memperketat keamanan atau script otomatisasi untuk Windows/Linux:

1. Fork repository ini.
2. Buat branch fitur baru (`git checkout -b fitur-keren`).
3. Commit perubahan kamu (`git commit -m 'Menambah fitur keamanan SSH'`).
4. Push ke branch (`git push origin fitur-keren`).
5. Buat Pull Request.

<br>

## 📞 Author & Contact

Dibuat dengan ❤️ dan ☕ oleh **Raja Zhafif Raditya Harahap**

* Project ini adalah bagian dari dokumentasi perjalanan belajar *System Administration* & *Cloud Engineering*.
* Jangan ragu untuk membuka **Issues** jika menemukan bug atau kesulitan saat setup.

Happy Server Building! 🚀
> Semua bisa dibuat asal kita niat
