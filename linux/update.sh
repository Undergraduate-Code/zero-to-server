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

preflight_update() {
	echo "[Preflight] Checking update prerequisites..."
	require_cmd apt
	require_cmd cloudflared
	require_cmd systemctl

	if [ ! -f /etc/systemd/system/myserver-tunnel.service ] || [ ! -f /etc/systemd/system/myserver-display.service ]; then
		echo "❌ Server services not installed yet. Run install.sh first."
		exit 1
	fi

	echo "[Preflight] OK"
}

if [ "$EUID" -ne 0 ]; then echo "❌ Run as ROOT!"; exit; fi

preflight_update

echo "--- UPDATING SYSTEM ---"
apt update && apt upgrade -y
apt autoremove -y

echo "--- UPDATING CLOUDFLARED ---"
cloudflared update

echo "--- RESTARTING SERVICES ---"
systemctl restart myserver-tunnel myserver-display

if [ -f "$SCRIPT_DIR/health-check.sh" ]; then
	bash "$SCRIPT_DIR/health-check.sh"
fi

echo "✅ DONE!"