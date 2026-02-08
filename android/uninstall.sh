#!/bin/bash
echo -e "\033[1;31m"
echo "⚠️  WARNING: THIS SCRIPT WILL DELETE ALL SERVER DATA!"
echo "    - Ubuntu (Proot-Distro) will be removed."
echo "    - The ~/server folder will be deleted."
echo -e "\033[0m"
read -p "Are you sure you want to proceed? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
    echo "Cancelled."
    exit
fi

echo "--- 1. KILLING PROCESSES ---"
pkill -f cloudflared
pkill -f proot
pkill -f nginx
pkill -f sshd
pkill -f termux-x11

echo "--- 2. REMOVING UBUNTU ---"
proot-distro remove ubuntu
proot-distro clear-cache

echo "--- 3. REMOVING SERVER FILES ---"
rm -rf ~/server
rm -rf ~/.cloudflared
rm -rf ~/.ssh/known_hosts
rm -rf ~/zero-to-server/android/server.sh

# Remove nginx config
rm -rf $PREFIX/etc/nginx/nginx.conf

echo "✅ CLEAN! Termux restored to original state."