#!/bin/bash
if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

echo -e "\033[1;31m"
echo "⚠️  WARN: This will remove Systemd Services and the /opt/serverlab folder."
echo -e "\033[0m"
read -p "Are you sure? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then exit; fi

echo "--- 1. STOP & DISABLE SERVICES ---"
systemctl stop myserver-tunnel
systemctl stop myserver-display
systemctl disable myserver-tunnel
systemctl disable myserver-display

echo "--- 2. REMOVING SERVICE FILES ---"
rm /etc/systemd/system/myserver-tunnel.service
rm /etc/systemd/system/myserver-display.service
systemctl daemon-reload
systemctl reset-failed

echo "--- 3. REMOVING SERVER FILES ---"
rm -rf /opt/serverlab
rm -rf /etc/cloudflared

echo "--- 4. UNINSTALL CLOUDFLARED (OPTIONAL) ---"
read -p "Uninstall cloudflared package? (y/n): " rm_pkg
if [[ "$rm_pkg" == "y" ]]; then
    apt remove cloudflared -y
    apt autoremove -y
fi

echo "✅ CLEAN! Linux Server shutdown."