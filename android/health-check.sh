#!/bin/bash
set -uo pipefail

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

TOKEN_FILE="$HOME/.config/zero-to-server/cloudflared.token"

check "token_file" "test -s \"$TOKEN_FILE\"" "token file present"
check "cloudflared_process" "pgrep -f 'cloudflared tunnel run'" "cloudflared process running"
check "novnc_proxy_process" "pgrep -f 'novnc_proxy --vnc localhost:5900 --listen 6080'" "novnc_proxy process running"
check "nginx_process" "pgrep -x nginx" "nginx process running"
check "sshd_process" "pgrep -x sshd" "sshd process running"

if command -v ss >/dev/null 2>&1; then
    check "port_8080" "ss -ltn | awk '{print \$4}' | grep -qE '(:|\\.)8080$'" "port 8080 listening"
    check "port_6080" "ss -ltn | awk '{print \$4}' | grep -qE '(:|\\.)6080$'" "port 6080 listening"
fi

if [ "$fail_count" -gt 0 ]; then
    echo "RESULT|FAIL|passed=$pass_count;failed=$fail_count;total=$total_count"
    exit 1
fi

echo "RESULT|PASS|passed=$pass_count;failed=$fail_count;total=$total_count"
exit 0
