#!/bin/bash
# Creator : BrotherZhafif
# Maintainer :

# Created : 9 February 2025

if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

echo "[1/5] Update & Install Tools..."
apt update && apt upgrade -y
apt install git wget curl python3 python3-pip python3-venv -y

echo "[2/5] Install Cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    ARCH=$(dpkg --print-architecture)
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb
    dpkg -i cloudflared-linux-${ARCH}.deb
    rm cloudflared-linux-${ARCH}.deb
fi

echo "[3/5] Setup noVNC & Venv..."
mkdir -p /opt/serverlab
cd /opt/serverlab
python3 -m venv venv
source venv/bin/activate

if [ ! -d "noVNC" ]; then git clone --depth 1 https://github.com/novnc/noVNC.git; fi
pip install websockify

# Intro Page
cat <<EOF > noVNC/index.html
<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>Linux Server</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:'Courier New';display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.box{text-align:center;border:1px solid #30363d;padding:40px;background:#161b22;border-radius:10px}
h1{color:#58a6ff}a{background:#238636;color:white;padding:10px 20px;text-decoration:none;border-radius:5px}</style>
</head><body><div class='box'><h1>LINUX SERVER</h1><a href='vnc.html'>🖥️ DISPLAY</a></div></body></html>
EOF

echo ""
read -p "Paste Token Cloudflare: " TOKEN

echo "[4/5] Setup Systemd Service (Auto-Start)..."
# Service Tunnel
cat <<EOF > /etc/systemd/system/myserver-tunnel.service
[Unit]
Description=Cloudflare Tunnel
After=network.target
[Service]
ExecStart=/usr/bin/cloudflared tunnel run --token $TOKEN
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

# Service Display
cat <<EOF > /etc/systemd/system/myserver-display.service
[Unit]
Description=Web Display
After=network.target
[Service]
ExecStart=/opt/serverlab/venv/bin/python3 /opt/serverlab/venv/bin/websockify --web /opt/serverlab/noVNC 6080 localhost:5900
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF

echo "[5/5] Menyalakan Service..."
systemctl daemon-reload
systemctl enable myserver-tunnel myserver-display
systemctl start myserver-tunnel myserver-display

echo "✅ SELESAI! Server otomatis nyala saat booting."