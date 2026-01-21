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
echo -e "${HIJAU}[1/7] Membersihkan sisa file & proses lama...${NC}"
termux-wake-lock
pkill -9 cloudflared 2>/dev/null
pkill -9 nginx 2>/dev/null
pkill -9 sshd 2>/dev/null
pkill -f "novnc_proxy" 2>/dev/null
rm -f server.sh start.sh tunnel.log
rm -rf $PREFIX/etc/nginx/nginx.conf

# 2. INSTALL PACKAGE PENTING
echo -e "${HIJAU}[2/7] Mengupdate & Install Package...${NC}"
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install git wget nginx openssh tur-repo proot-distro -y
pkg install cloudflared -y

# 3. SETUP UBUNTU (CORE VS CODE)
echo -e "${HIJAU}[3/7] Menginstall Ubuntu (Proot)...${NC}"
if proot-distro list | grep -q "ubuntu (installed)"; then
    echo "Ubuntu sudah terinstall, skip download."
else
    proot-distro install ubuntu
fi

echo -e "${HIJAU}[4/7] Konfigurasi Internal Ubuntu...${NC}"
# Login ke Ubuntu & jalankan perintah setup otomatis
proot-distro login ubuntu -- bash -c '
    apt update -y
    apt install openssh-server git curl nano net-tools -y

    # Setup Config SSH Ubuntu (Port 2022)
    echo "Port 2022" >> /etc/ssh/sshd_config
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    
    # Buat folder project
    mkdir -p /root/project
'

# Setup Password Ubuntu
echo ""
echo -e "${MERAH}⚠️  SET PASSWORD UBUNTU (Untuk Login VS Code) ⚠️${NC}"
proot-distro login ubuntu -- passwd

# 4. DOWNLOAD noVNC + LANDING PAGE
echo -e "${HIJAU}[5/7] Menyiapkan noVNC...${NC}"
if [ ! -d "noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git
fi

# Input branding (Custom)
echo -e "${HIJAU}[INFO] Masukkan nama web untuk halaman depan...${NC}"
read -p "Nama Web (contoh: Raja's Lab) > " WEB_TITLE
read -p "Nama Pemilik (contoh: Raja Zhafif) > " WEB_OWNER

WEB_TITLE=${WEB_TITLE:-"Raja's Server Lab"}
WEB_OWNER=${WEB_OWNER:-"Raja Zhafif"}

# Generate index.html
if [ -d "noVNC" ]; then
cat <<EOF > noVNC/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${WEB_TITLE}</title>
    <style>
        body{background-color:#0d1117;color:#c9d1d9;font-family:'Courier New',Courier,monospace;display:flex;flex-direction:column;align-items:center;justify-content:center;height:100vh;margin:0}
        .container{text-align:center;border:1px solid #30363d;padding:40px;border-radius:10px;background:#161b22;box-shadow:0 0 20px rgba(0,255,0,0.1)}
        h1{color:#58a6ff}p{color:#8b949e}.btn{display:inline-block;padding:12px 24px;margin:10px;text-decoration:none;color:#fff;border-radius:6px;font-weight:bold;transition:0.3s}
        .btn-full{background-color:#238636}.btn-lite{border:1px solid #30363d;color:#c9d1d9}
        .footer{margin-top:20px;font-size:12px;color:#484f58}
    </style>
</head>
<body>
    <div class="container">
        <h1>ACCESS GRANTED</h1>
        <p>Welcome to <strong>${WEB_OWNER}'s</strong> Private Cloud Lab.</p>
        <a href="vnc.html" class="btn btn-full">🚀 FULL CONTROL (GUI)</a>
        <a href="vnc_lite.html" class="btn btn-lite">⚡ LITE MODE</a>
        <div class="footer">System Status: ONLINE | Encrypted via Cloudflare</div>
    </div>
</body>
</html>
EOF
fi

# 5. BUAT CONFIG NGINX OTOMATIS
echo -e "${HIJAU}[6/7] Membuat Konfigurasi Nginx...${NC}"
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
        location / {
            proxy_pass http://127.0.0.1:6080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host \$host;
        }
        location ~ /\\.(?!well-known) { deny all; }
        location ~ /(README.md|AUTHORS|LICENSE|package.json) { deny all; }
    }
}
EOF

# 6. INPUT TOKEN CLOUDFLARE
echo ""
echo -e "${BIRU}===============================================${NC}"
echo -e "Silakan Paste Token Cloudflare Tunnel (eyJhIjoi...) :"
read -p "Token > " INPUT_TOKEN

# 7. BUAT SCRIPT SERVER.SH FINAL
echo -e "${HIJAU}[7/7] Membuat Script server.sh (Fixed Version)...${NC}"
cat <<EOF > server.sh
#!/bin/bash

# TOKEN AUTOMATIS
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

# 1. Nyalakan Ubuntu SSH (Port 2022) -> UTAMA BUAT VS CODE
echo -e "\${HIJAU}[+] Menyalakan Ubuntu SSH (Port 2022)...\${NC}"
# FIX: Buat folder run dulu biar SSH gak crash/bad handshake
proot-distro login ubuntu -- mkdir -p /run/sshd
# Jalankan SSH
nohup proot-distro login ubuntu -- /usr/sbin/sshd -D > /dev/null 2>&1 &

# 2. Nyalakan Termux SSH (Port 8022) -> CADANGAN
echo -e "\${HIJAU}[+] Menyalakan Termux SSH (Port 8022)...\${NC}"
sshd

# 3. Nyalakan noVNC & Nginx
echo -e "\${HIJAU}[+] Menyalakan GUI & Web...\${NC}"
if [ -d "noVNC" ]; then
    nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
fi
nginx

# 4. Konek Cloudflare
if [ -n "\$TOKEN" ]; then
    echo -e "\${HIJAU}[+] Menghubungkan Cloudflare Tunnel...\${NC}"
    nohup cloudflared tunnel run --token \$TOKEN > tunnel.log 2>&1 &
    
    echo -e "\${BIRU}✅ SERVER SIAP! Akses di:\${NC}"
    echo -e "🖥️  Layar HP:   https://display.brotherzhafif.my.id"
    echo -e "📟 VS Code:    ssh server.brotherzhafif.my.id"
    echo -e "    (User: root | Port Asli: 2022)"
else
    echo "❌ ERROR: Token Cloudflare Kosong! Edit file server.sh"
fi
EOF

chmod +x server.sh

echo ""
echo -e "${BIRU}✅ INSTALASI SELESAI! ${NC}"
echo "Jalankan server dengan: ./server.sh"