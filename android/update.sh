#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${RED}❌ Missing required command: $cmd${NC}"
        exit 1
    fi
}

preflight_update() {
    echo -e "${BLUE}[Preflight] Checking update prerequisites...${NC}"
    require_cmd pkg
    require_cmd proot-distro
    require_cmd cloudflared

    if [ ! -f "./server.sh" ]; then
        echo -e "${RED}❌ server.sh not found. Run install.sh first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}[Preflight] OK${NC}"
}

# COLORS
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}===============================================${NC}"

preflight_update
echo -e "${BLUE}      SYSTEM UPDATE (TERMUX + UBUNTU)          ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. KILL ALL PROCESSES (Ensure smooth update)
echo -e "${GREEN}[1/3] Stopping server temporarily...${NC}"
termux-wake-lock
pkill cloudflared 2>/dev/null || true
pkill nginx 2>/dev/null || true
pkill sshd 2>/dev/null || true
pkill -f "novnc_proxy" 2>/dev/null || true

# 2. UPDATE TERMUX (HOST)
echo -e "${GREEN}[2/3] Updating Termux System...${NC}"
pkg update -y -o Dpkg::Options::="--force-confnew"
pkg upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install cloudflared -y  # Ensure latest cloudflared

# 3. UPDATE UBUNTU (GUEST/PROOT) -> IMPORTANT FOR VS CODE
echo -e "${GREEN}[3/3] Updating Ubuntu System...${NC}"
if proot-distro list | grep -q "ubuntu (installed)"; then
    # Login to Ubuntu briefly just to update, then exit
    proot-distro login ubuntu -- bash -c 'apt update -y && apt upgrade -y && apt autoremove -y'
else
    echo -e "${RED}Ubuntu not found! Skipping Ubuntu update.${NC}"
fi

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}✅ UPDATE COMPLETE! Starting Server...${NC}"
echo -e "${BLUE}===============================================${NC}"

# 4. CALL SERVER.SH
if [ -f "./server.sh" ]; then
    chmod +x server.sh
    ./server.sh
else
    echo -e "${RED}❌ Critical! server.sh file is missing.${NC}"
    echo "Please run install.sh again."
fi

if [ -f "$SCRIPT_DIR/health-check.sh" ]; then
    bash "$SCRIPT_DIR/health-check.sh"
fi