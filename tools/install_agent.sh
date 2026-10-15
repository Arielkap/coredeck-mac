#!/bin/bash
set -e

# ==========================================================
# CoreDeck Remote Telemetry Agent Installer
# Lightweight, Zero-Dependency Linux Daemon
# ==========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}======================================================"
echo -e " 🚀 CoreDeck Telemetry Agent Installer"
echo -e "======================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}❌ Uruchom ten skrypt jako root (lub użyj sudo).${NC}"
    exit 1
fi

# Detect Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}📦 Instalacja python3...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -y && apt-get install -y python3
    elif command -v yum &> /dev/null; then
        yum install -y python3
    elif command -v dnf &> /dev/null; then
        dnf install -y python3
    else
        echo -e "${RED}❌ Nie znaleziono menedżera pakietów. Zainstaluj python3 ręcznie.${NC}"
        exit 1
    fi
fi

INSTALL_DIR="/etc/coredeck-agent"
mkdir -p "$INSTALL_DIR"

# Generate or keep token
TOKEN_FILE="$INSTALL_DIR/token"
if [ ! -f "$TOKEN_FILE" ]; then
    RAND_HEX=$(head -c 16 /dev/urandom | xxd -p 2>/dev/null || date +%s%N | md5sum | head -c 16)
    echo "CORE-AG-${RAND_HEX}" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
fi
AGENT_TOKEN=$(cat "$TOKEN_FILE")

# Write Python daemon
AGENT_SCRIPT="/usr/local/bin/coredeck-agent.py"
cat << 'EOF' > "$AGENT_SCRIPT"
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import socket
import time
from urllib.parse import urlparse, parse_qs

PORT = 9123
TOKEN_PATH = "/etc/coredeck-agent/token"

def get_auth_token():
    try:
        with open(TOKEN_PATH, "r") as f:
            return f.read().strip()
    except Exception:
        return ""

def collect_telemetry():
    # Load
    try:
        with open("/proc/loadavg") as f:
            parts = f.read().split()
            load = [float(parts[0]), float(parts[1]), float(parts[2])]
    except Exception:
        load = [0.0, 0.0, 0.0]

    # Memory
    total_mb, used_mb, ram_pct = 0.0, 0.0, 0.0
    try:
        mem = {}
        with open("/proc/meminfo") as f:
            for line in f:
                p = line.split(":")
                if len(p) == 2:
                    mem[p[0].strip()] = float(p[1].strip().split()[0])
        total_mb = round(mem.get("MemTotal", 0) / 1024.0, 1)
        avail_mb = round(mem.get("MemAvailable", mem.get("MemFree", 0)) / 1024.0, 1)
        used_mb = round(total_mb - avail_mb, 1)
        ram_pct = round((used_mb / total_mb) * 100.0, 1) if total_mb > 0 else 0.0
    except Exception:
        pass

    # Disk /
    total_gb, used_gb, free_gb, disk_pct = 0.0, 0.0, 0.0, 0.0
    try:
        st = os.statvfs("/")
        total_gb = round((st.f_blocks * st.f_frsize) / (1024**3), 1)
        free_gb = round((st.f_bavail * st.f_frsize) / (1024**3), 1)
        used_gb = round(total_gb - free_gb, 1)
        disk_pct = round((used_gb / total_gb) * 100.0, 1) if total_gb > 0 else 0.0
    except Exception:
        pass

    # Uptime
    uptime = "0h"
    try:
        with open("/proc/uptime") as f:
            up_secs = float(f.read().split()[0])
        d = int(up_secs // 86400)
        h = int((up_secs % 86400) // 3600)
        uptime = f"{d}d {h}h" if d > 0 else f"{h}h"
    except Exception:
        pass

    return {
        "status": "online",
        "hostname": socket.gethostname(),
        "ram": {"total_mb": total_mb, "used_mb": used_mb, "percent": ram_pct},
        "load": load,
        "uptime": uptime,
        "disk": {"total_gb": total_gb, "used_gb": used_gb, "free_gb": free_gb, "percent": disk_pct},
        "timestamp": str(time.time())
    }

class TelemetryHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass # Quiet mode

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path not in ["/", "/stats", "/api/vps_stats"]:
            self.send_response(404)
            self.end_headers()
            return

        expected_token = get_auth_token()
        if expected_token:
            query = parse_qs(parsed.query)
            provided_token = query.get("key", [""])[0] or query.get("token", [""])[0]
            header_key = self.headers.get("X-API-Key", "")
            auth_header = self.headers.get("Authorization", "")
            if auth_header.startswith("Bearer "):
                auth_header = auth_header[7:].strip()

            if provided_token != expected_token and header_key != expected_token and auth_header != expected_token:
                self.send_response(401)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(b'{"error": "Unauthorized"}\n')
                return

        telemetry = collect_telemetry()
        data = json.dumps(telemetry).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), TelemetryHandler) as httpd:
        httpd.serve_forever()
EOF

chmod +x "$AGENT_SCRIPT"

# Setup Systemd Service
SERVICE_FILE="/etc/systemd/system/coredeck-agent.service"
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=CoreDeck Remote Telemetry Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 $AGENT_SCRIPT
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable coredeck-agent.service
systemctl restart coredeck-agent.service

# Get Public IP
PUBLIC_IP=$(curl -s -4 ifconfig.me || curl -s -4 icanhazip.com || hostname -I | awk '{print $1}')

echo ""
echo -e "${GREEN}======================================================"
echo -e " ✅ CoreDeck Agent został pomyślnie zainstalowany!"
echo -e "======================================================${NC}"
echo -e "Wprowadź poniższe dane w CoreDeck na Macu:"
echo ""
echo -e "  📡 ${CYAN}Adres URL:${NC}      http://${PUBLIC_IP}:9123/stats"
echo -e "  🔑 ${CYAN}Klucz API / Token:${NC} ${AGENT_TOKEN}"
echo ""
echo -e "Test lokalny: ${YELLOW}curl -H 'X-API-Key: ${AGENT_TOKEN}' http://localhost:9123/stats${NC}"
echo -e "${GREEN}======================================================${NC}"
