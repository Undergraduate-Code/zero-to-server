#!/bin/bash
echo -e "\033[1;31m"
echo "⚠️  PERINGATAN: SCRIPT INI AKAN MENGHAPUS SEMUA DATA SERVER!"
echo "    - Ubuntu (Proot-Distro) akan dihapus."
echo "    - Folder ~/server akan dihapus."
echo -e "\033[0m"
read -p "Yakin mau lanjut? (y/n): " confirm

if [[ "$confirm" != "y" ]]; then
    echo "Dibatalkan."
    exit
fi

echo "--- 1. MEMATIKAN PROSES ---"
pkill -f cloudflared
pkill -f proot
pkill -f nginx
pkill -f sshd
pkill -f termux-x11

echo "--- 2. MENGHAPUS UBUNTU ---"
proot-distro remove ubuntu
proot-distro clear-cache

echo "--- 3. MENGHAPUS FILE SERVER ---"
rm -rf ~/server
rm -rf ~/.cloudflared
rm -rf ~/.ssh/known_hosts
rm -rf ~/zero-to-server/android/server.sh

# Hapus config nginx
rm -rf $PREFIX/etc/nginx/nginx.conf

echo "✅ BERSIH! Termux sudah kembali seperti semula."