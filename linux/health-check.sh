#!/bin/bash
set -uo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "❌ Run as ROOT!"
    exit 1
fi

pass_count=0
fail_count=0
total_count=0

check() {
    local component="$1"
    local cmd="$2"
    local detail="$3"
    total_count=$((total_count + 1))

    if eval "$cmd" >/dev/null 2>&1; then
        pass_count=$((pass_count + 1))
        echo "PASS|$component|$detail"
    else
        fail_count=$((fail_count + 1))
        echo "FAIL|$component|$detail"
    fi
}

check "tunnel_service" "systemctl is-active --quiet myserver-tunnel" "myserver-tunnel active"
check "display_service" "systemctl is-active --quiet myserver-display" "myserver-display active"
check "token_env" "test -f /etc/serverlab/serverlab.env" "token env file present"
check "port_6080" "ss -ltn | awk '{print \$4}' | grep -qE '(:|\\.)6080$'" "port 6080 listening"
check "port_5900" "ss -ltn | awk '{print \$4}' | grep -qE '(:|\\.)5900$'" "port 5900 listening"
check "cloudflared_process" "pgrep -f 'cloudflared tunnel run'" "cloudflared process running"
check "websockify_process" "pgrep -f 'websockify --web /opt/serverlab/noVNC 6080 localhost:5900'" "websockify process running"

if [ "$fail_count" -gt 0 ]; then
    echo "RESULT|FAIL|passed=$pass_count;failed=$fail_count;total=$total_count"
    exit 1
fi

echo "RESULT|PASS|passed=$pass_count;failed=$fail_count;total=$total_count"
exit 0
