#!/bin/bash

set -euo pipefail

# Creator : BrotherZhafif
# Maintainer :

# Created : 20 January 2025

# COLORS FOR STYLE
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   AUTO-INSTALLER ANDROID SERVER (ALL-IN-ONE)  ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# 1. CLEAN UP ENVIRONMENT
echo -e "${GREEN}[1/7] Cleaning up old files & processes...${NC}"
termux-wake-lock
pkill cloudflared 2>/dev/null || true
pkill nginx 2>/dev/null || true
pkill sshd 2>/dev/null || true
pkill -f "novnc_proxy" 2>/dev/null || true
rm -f server.sh start.sh tunnel.log
rm -f "$PREFIX/etc/nginx/nginx.conf"

# 2. INSTALL IMPORTANT PACKAGES
echo -e "${GREEN}[2/7] Updating & Installing Packages...${NC}"
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install git wget nginx openssh tur-repo proot-distro -y
pkg install cloudflared -y

# 3. SETUP UBUNTU (CORE VS CODE)
echo -e "${GREEN}[3/7] Installing Ubuntu (Proot)...${NC}"
if proot-distro list | grep -q "ubuntu (installed)"; then
    echo "Ubuntu is already installed, skipping download."
else
    proot-distro install ubuntu
fi

echo -e "${GREEN}[INFO] Choose Ubuntu SSH username (non-root)...${NC}"
read -r -p "Ubuntu SSH username [serverlab] > " UBUNTU_USER
UBUNTU_USER=${UBUNTU_USER:-serverlab}

if ! [[ "$UBUNTU_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    echo -e "${RED}Invalid username format. Use lowercase letters, numbers, underscore, hyphen.${NC}"
    exit 1
fi

echo -e "${GREEN}[4/7] Internal Ubuntu Configuration...${NC}"
# Login to Ubuntu & run automated setup commands
proot-distro login ubuntu -- bash -c "
    set -e
    apt update -y
    apt install openssh-server git curl nano net-tools -y

    # Setup Ubuntu SSH Config (Port 2022, no root login)
    if grep -qE '^\\s*#?\\s*Port\\s+' /etc/ssh/sshd_config; then
        sed -i 's/^\\s*#\\?\\s*Port\\s\\+.*/Port 2022/' /etc/ssh/sshd_config
    else
        echo 'Port 2022' >> /etc/ssh/sshd_config
    fi

    if grep -qE '^\\s*#?\\s*PermitRootLogin\\s+' /etc/ssh/sshd_config; then
        sed -i 's/^\\s*#\\?\\s*PermitRootLogin\\s\\+.*/PermitRootLogin no/' /etc/ssh/sshd_config
    else
        echo 'PermitRootLogin no' >> /etc/ssh/sshd_config
    fi

    if grep -qE '^\\s*#?\\s*PasswordAuthentication\\s+' /etc/ssh/sshd_config; then
        sed -i 's/^\\s*#\\?\\s*PasswordAuthentication\\s\\+.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    else
        echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
    fi

    if ! id -u '$UBUNTU_USER' >/dev/null 2>&1; then
        useradd -m -s /bin/bash '$UBUNTU_USER'
    fi

    mkdir -p /home/$UBUNTU_USER/project
    chown -R $UBUNTU_USER:$UBUNTU_USER /home/$UBUNTU_USER/project
"

# Setup Ubuntu Password
echo ""
echo -e "${RED}⚠️  SET UBUNTU PASSWORD FOR '$UBUNTU_USER' (For VS Code Login) ⚠️${NC}"
proot-distro login ubuntu -- passwd "$UBUNTU_USER"

# 4. DOWNLOAD noVNC + LANDING PAGE
echo -e "${GREEN}[5/7] Preparing noVNC...${NC}"
if [ ! -d "noVNC" ]; then
    git clone --depth 1 https://github.com/novnc/noVNC.git
fi

# Input branding (Custom)
echo -e "${GREEN}[INFO] Enter web name for the front page...${NC}"
read -p "Web Name (e.g., Raja's Lab) > " WEB_TITLE
read -p "Owner Name (e.g., Raja Zhafif) > " WEB_OWNER

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

# 5. CREATE AUTOMATIC NGINX CONFIG
echo -e "${GREEN}[6/7] Creating Nginx Configuration...${NC}"
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

# 6. INPUT CLOUDFLARE TOKEN
echo ""
echo -e "${BLUE}===============================================${NC}"
echo -e "Please Paste Cloudflare Tunnel Token (eyJhIjoi...) :"
read -r -s -p "Token > " INPUT_TOKEN
echo ""

TOKEN_DIR="$HOME/.config/zero-to-server"
TOKEN_FILE="$TOKEN_DIR/cloudflared.token"
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"
printf '%s\n' "$INPUT_TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

# 7. CREATE FINAL SERVER.SH SCRIPT
echo -e "${GREEN}[7/7] Creating server.sh Script (Fixed Version)...${NC}"
cat <<EOF > server.sh
#!/bin/bash

set -euo pipefail

TOKEN_FILE="\$HOME/.config/zero-to-server/cloudflared.token"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}=========================================\${NC}"
echo -e "\${BLUE}        ANDROID SERVER - ONLINE          \${NC}"
echo -e "\${BLUE}=========================================\${NC}"

termux-wake-lock

# Clean Processes
echo -e "\${GREEN}[+] Resetting server processes...\${NC}"
pkill -f "novnc_proxy" 2>/dev/null || true
pkill -f "nginx" 2>/dev/null || true
pkill -f "cloudflared" 2>/dev/null || true
pkill -f "sshd" 2>/dev/null || true

# 1. Start Ubuntu SSH (Port 2022) -> MAIN FOR VS CODE
echo -e "\${GREEN}[+] Starting Ubuntu SSH (Port 2022)...\${NC}"
# FIX: Create run folder first to prevent SSH crash/bad handshake
proot-distro login ubuntu -- mkdir -p /run/sshd
# Run SSH
nohup proot-distro login ubuntu -- /usr/sbin/sshd -D > /dev/null 2>&1 &

# 2. Start Termux SSH (Port 8022) -> BACKUP
echo -e "\${GREEN}[+] Starting Termux SSH (Port 8022)...\${NC}"
sshd

# 3. Start noVNC & Nginx
echo -e "\${GREEN}[+] Starting GUI & Web...\${NC}"
if [ -d "noVNC" ]; then
    nohup ./noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 > /dev/null 2>&1 &
fi
nginx

# 4. Connect Cloudflare
if [ -s "\$TOKEN_FILE" ]; then
    TOKEN=\$(cat "\$TOKEN_FILE")
    echo -e "\${GREEN}[+] Connecting Cloudflare Tunnel...\${NC}"
    nohup cloudflared tunnel run --token \$TOKEN > tunnel.log 2>&1 &
    
    echo -e "\${BLUE}✅ SERVER READY! Access at:\${NC}"
    echo -e "🖥️  Phone Screen:   https://display.brotherzhafif.my.id"
    echo -e "📟 VS Code:    ssh server.brotherzhafif.my.id"
    echo -e "    (User: $UBUNTU_USER | Original Port: 2022)"
else
    echo "❌ ERROR: Cloudflare token file missing/empty: \$TOKEN_FILE"
fi
EOF

chmod +x server.sh

echo ""
echo -e "${BLUE}✅ INSTALLATION COMPLETE! ${NC}"
echo "Run server with: ./server.sh"