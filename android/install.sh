#!/bin/bash

# Creator : BrotherZhafif
# Maintainer :

# Created : 20 January 2025

# WARNA BIAR KEREN
HIJAU='\033[0;32m'
BIRU='\033[0;34m'
MERAH='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BIRU}===============================================${NC}"
echo -e "${BIRU}   AUTO-INSTALLER SERVER Android (ALL-IN-ONE)  ${NC}"
echo -e "${BIRU}===============================================${NC}"
echo ""

# 1. CLEAN UP LINGKUNGAN
echo -e "${HIJAU}[1/6] Membersihkan sisa file & proses lama...${NC}"
termux-wake-lock
pkill -9 cloudflared 2>/dev/null
pkill -9 nginx 2>/dev/null
pkill -9 sshd 2>/dev/null
pkill -9 novnc_proxy 2>/dev/null
rm -f server.sh start.sh tunnel.log
rm -rf $PREFIX/etc/nginx/nginx.conf

# 2. INSTALL PACKAGE PENTING
echo -e "${HIJAU}[2/6] Mengupdate & Install Package (Sabar ya)...${NC}"
pkg update -y && pkg upgrade -y
pkg install git wget nginx openssh tur-repo -y
pkg install cloudflared -y

# 3. SETUP SSH PASSWORD
echo -e "${HIJAU}[3/6] Setup Password SSH...${NC}"
echo -e "${MERAH}⚠️  Masukkan Password untuk login Terminal (ingat baik-baik!):${NC}"
passwd

# 4. DOWNLOAD noVNC
echo -e "${HIJAU}[4/6] Menyiapkan noVNC...${NC}"
if [ ! -d "noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git
else
    echo "Folder noVNC sudah ada, skip download."
fi

# 5. BUAT CONFIG NGINX OTOMATIS
echo -e "${HIJAU}[5/6] Membuat Konfigurasi Nginx...${NC}"
mkdir -p $PREFIX/etc/nginx
cat <<EOF > $PREFIX/etc/nginx/nginx.conf
worker_processes 1;
events { worker_connections 1024; }
http {
    include mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 8080;
        server_name localhost;

        # 1. Ini Konfigurasi Utama (Proxy ke noVNC)
        location / {
            proxy_pass http://127.0.0.1:6080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host \$host;
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
}
EOF

# 6. INPUT TOKEN CLOUDFLARE
echo ""
echo -e "${BIRU}===============================================${NC}"
echo -e "Silakan Paste Token Cloudflare Tunnel (eyJhIjoi...) :"
read -p "Token > " INPUT_TOKEN

# 7. BUAT SCRIPT SERVER.SH FINAL
echo -e "${HIJAU}[6/6] Membuat Script server.sh...${NC}"
cat <<EOF > server.sh
#!/bin/bash

# TOKEN AUTOMATIS DARI INSTALLER
TOKEN="$INPUT_TOKEN"

HIJAU='\033[0;32m'
BIRU='\033[0;34m'
NC='\033[0m'

echo -e "\${BIRU}=========================================\${NC}"
echo -e "\${BIRU}        SERVER ANDROID - ONLINE          \${NC}"
echo -e "\${BIRU}=========================================\${NC}"

termux-wake-lock

# Bersihkan Proses
echo -e "\${HIJAU}[+] Reset proses server...\${NC}"
pkill -f "novnc_proxy"
pkill -f "nginx"
pkill -f "cloudflared"
pkill -f "sshd"

# Nyalakan SSH (Port 8022) -> Jalur 'server'
echo -e "\${HIJAU}[+] Menyalakan SSH Server (Port 8022)...\${NC}"
sshd

# Nyalakan noVNC (Port 6080) -> Diproses Nginx
echo -e "\${HIJAU}[+] Menyalakan noVNC...\${NC}"
if [ -d "noVNC" ]; then
    nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
fi

# Nyalakan Nginx (Port 8080) -> Jalur 'display'
echo -e "\${HIJAU}[+] Menyalakan Nginx...\${NC}"
nginx

# Konek Cloudflare
if [ -n "\$TOKEN" ]; then
    echo -e "\${HIJAU}[+] Menghubungkan Cloudflare Tunnel...\${NC}"
    nohup cloudflared tunnel run --token \$TOKEN > tunnel.log 2>&1 &
    
    echo -e "\${BIRU}✅ SERVER SIAP! Akses di:\${NC}"
    echo -e "🖥️  Layar HP:   https://display.brotherzhafif.my.id/vnc.html"
    echo -e "📟 Terminal:   ssh server.brotherzhafif.my.id"
    echo -e "(User SSH: \$(whoami) | Port: 22 di Cloudflare, 8022 Lokal)"
else
    echo "❌ ERROR: Token Cloudflare Kosong! Edit file ini."
fi
EOF

chmod +x server.sh

echo ""
echo -e "${BIRU}✅ INSTALASI SELESAI! ${NC}"
echo "Ketik perintah ini untuk menyalakan server:"
echo -e "${HIJAU}./server.sh${NC}"