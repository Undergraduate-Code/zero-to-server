#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

echo "--- UPDATING SYSTEM ---"
apt update && apt upgrade -y
apt autoremove -y

echo "--- UPDATING CLOUDFLARED ---"
cloudflared update

echo "--- RESTARTING SERVICES ---"
systemctl restart myserver-tunnel myserver-display
echo "✅ DONE!"