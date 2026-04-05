#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "❌ Missing required command: $cmd"
        exit 1
    fi
}

preflight_install() {
    echo "[Preflight] Running strict checks..."
    require_cmd apt
    require_cmd systemctl
    require_cmd python3

    if ! getent hosts github.com >/dev/null 2>&1; then
        echo "❌ DNS/internet check failed (github.com not reachable)."
        exit 1
    fi

    if ss -ltn | awk '{print $4}' | grep -qE '(:|\.)6080$'; then
        echo "❌ Port 6080 is already in use. Stop conflicting service first."
        exit 1
    fi

    if ! ss -ltn | awk '{print $4}' | grep -qE '(:|\.)5900$'; then
        echo "❌ Port 5900 is not listening. Start your VNC server first."
        exit 1
    fi

    echo "[Preflight] OK"
}

# Creator : BrotherZhafif
# Maintainer :

# Created : 9 February 2025

if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

preflight_install

echo "[1/5] Update & Install Tools..."
apt update && apt upgrade -y
apt install git wget curl openssh-server python3 python3-pip python3-venv -y

echo "[2/5] Installing Cloudflared..."
if ! command -v cloudflared &> /dev/null; then
    ARCH=$(dpkg --print-architecture)
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb
    dpkg -i cloudflared-linux-${ARCH}.deb
    rm cloudflared-linux-${ARCH}.deb
fi

echo "[3/5] Setup noVNC & Venv..."
mkdir -p /opt/serverlab
cd /opt/serverlab
if [ ! -d venv ]; then
    python3 -m venv venv
fi
source venv/bin/activate

if [ ! -d "noVNC" ]; then git clone --depth 1 https://github.com/novnc/noVNC.git; fi
pip install --upgrade pip
pip install --upgrade websockify

# Intro Page
cat <<EOF > noVNC/index.html
<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'><title>Linux Server</title>
<style>body{background:#0d1117;color:#c9d1d9;font-family:'Courier New';display:flex;align-items:center;justify-content:center;height:100vh;margin:0}
.box{text-align:center;border:1px solid #30363d;padding:40px;background:#161b22;border-radius:10px}
h1{color:#58a6ff}a{background:#238636;color:white;padding:10px 20px;text-decoration:none;border-radius:5px}</style>
</head><body><div class='box'><h1>LINUX SERVER</h1><a href='vnc.html'>🖥️ DISPLAY</a></div></body></html>
EOF

echo ""
read -r -s -p "Paste Cloudflare Token: " TOKEN
echo ""

install -d -m 750 /etc/serverlab
printf 'CLOUDFLARE_TOKEN=%q\n' "$TOKEN" > /etc/serverlab/serverlab.env

if ! id -u serverlab >/dev/null 2>&1; then
    useradd --system --home /opt/serverlab --shell /usr/sbin/nologin serverlab
fi
chown -R serverlab:serverlab /opt/serverlab
chown root:serverlab /etc/serverlab/serverlab.env
chmod 640 /etc/serverlab/serverlab.env

echo "[4/5] Setup Systemd Service (Auto-Start)..."
# Service Tunnel
cat <<EOF > /etc/systemd/system/myserver-tunnel.service
[Unit]
Description=Cloudflare Tunnel
After=network.target
[Service]
EnvironmentFile=/etc/serverlab/serverlab.env
ExecStart=/bin/sh -c '/usr/bin/cloudflared tunnel run --token "$CLOUDFLARE_TOKEN"'
Restart=always
RestartSec=3
User=serverlab
Group=serverlab
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/serverlab
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
RestartSec=3
User=serverlab
Group=serverlab
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/serverlab
[Install]
WantedBy=multi-user.target
EOF

echo "[5/5] Starting Services..."
systemctl daemon-reload
systemctl enable myserver-tunnel myserver-display
systemctl start myserver-tunnel myserver-display

if [ -f "$SCRIPT_DIR/health-check.sh" ]; then
    bash "$SCRIPT_DIR/health-check.sh"
fi

echo "✅ DONE! Server automatically starts on boot."