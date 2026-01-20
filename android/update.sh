#!/bin/bash

HIJAU='\033[0;32m'
BIRU='\033[0;34m'
NC='\033[0m'

echo -e "${BIRU}=========================================${NC}"
echo -e "${BIRU}   UPDATE SYSTEM & CLOUDFLARED           ${NC}"
echo -e "${BIRU}=========================================${NC}"

# 1. Matikan server dulu biar file gak bentrok
echo -e "${HIJAU}[+] Mematikan server sementara...${NC}"
pkill -9 cloudflared
pkill -9 nginx
pkill -9 sshd

# 2. Update Paket Termux (termasuk cloudflared kalau install via pkg)
echo -e "${HIJAU}[+] Mengecek update sistem...${NC}"
pkg update -y && pkg upgrade -y

# 3. Cek versi sekarang
echo -e "${HIJAU}[+] Versi Cloudflared saat ini:${NC}"
cloudflared --version

echo -e "${BIRU}=========================================${NC}"
echo -e "${BIRU}✅ UPDATE SELESAI! ${NC}"
echo -e "Silakan nyalakan server lagi dengan: ./server.sh"