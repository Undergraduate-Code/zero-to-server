#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

echo "--- UPDATING SYSTEM ---"
apt update && apt upgrade -y
apt autoremove -y

echo "--- UPDATING CLOUDFLARED ---"
cloudflared update

echo "--- RESTARTING SERVICES ---"
systemctl restart myserver-tunnel
systemctl restart myserver-display
echo "✅ DONE!"