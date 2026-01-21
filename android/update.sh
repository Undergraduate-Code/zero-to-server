#!/bin/bash

# WARNA
HIJAU='\033[0;32m'
BIRU='\033[0;34m'
MERAH='\033[0;31m'
NC='\033[0m'

clear
echo -e "${BIRU}===============================================${NC}"
echo -e "${BIRU}      SYSTEM UPDATE (TERMUX + UBUNTU)          ${NC}"
echo -e "${BIRU}===============================================${NC}"

# 1. MATIKAN SEMUA PROSES (Biar update lancar)
echo -e "${HIJAU}[1/3] Mematikan server sementara...${NC}"
termux-wake-lock
pkill -9 cloudflared 2>/dev/null
pkill -9 nginx 2>/dev/null
pkill -9 sshd 2>/dev/null
pkill -f "novnc_proxy" 2>/dev/null

# 2. UPDATE TERMUX (HOST)
echo -e "${HIJAU}[2/3] Update System Termux...${NC}"
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install cloudflared -y  # Pastikan cloudflared terbaru

# 3. UPDATE UBUNTU (GUEST/PROOT) -> PENTING BUAT VS CODE
echo -e "${HIJAU}[3/3] Update System Ubuntu...${NC}"
if proot-distro list | grep -q "ubuntu (installed)"; then
    # Masuk ke Ubuntu sebentar cuma buat update, lalu keluar lagi
    proot-distro login ubuntu -- bash -c 'apt update -y && apt upgrade -y && apt autoremove -y'
else
    echo -e "${MERAH}Ubuntu tidak ditemukan! Skip update Ubuntu.${NC}"
fi

echo -e "${BIRU}===============================================${NC}"
echo -e "${BIRU}✅ UPDATE SELESAI! Menyalakan Server...${NC}"
echo -e "${BIRU}===============================================${NC}"
sleep 2

# 4. PANGGIL SERVER.SH
if [ -f "./server.sh" ]; then
    chmod +x server.sh
    ./server.sh
else
    echo -e "${MERAH}❌ Gawat! File server.sh hilang.${NC}"
    echo "Silakan jalankan install.sh lagi."
fi