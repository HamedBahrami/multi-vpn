#!/usr/bin/env bash
#
# Paqet — Server Setup
#
# Installs paqet server binary, detects network parameters, generates config,
# and creates a systemd service.
#
# Usage: sudo bash setup.sh <interface> [port] [kcp-key]
#   interface: Network interface (e.g., ens3)
#   port:      Listen port (default: 9999)
#   kcp-key:   KCP encryption key (default: auto-generated)
#
set -euo pipefail

IFACE="${1:-}"
PORT="${2:-9999}"
KCP_KEY="${3:-}"

if [[ -z "$IFACE" ]]; then
    echo "Usage: $0 <interface> [port] [kcp-key]"
    echo "Example: $0 ens3 9999"
    echo ""
    echo "Available interfaces:"
    ip -br link show | grep -v lo
    exit 1
fi

INSTALL_DIR="/opt/paqet"
CONFIG_FILE="/etc/paqet/server.yaml"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Paqet Server Setup ==="
echo "Interface: $IFACE"
echo "Port:      $PORT"

# --- Detect network parameters ---
echo ""
echo "Detecting network parameters..."

# Server IP
SERVER_IP=$(ip -4 addr show "$IFACE" | grep -oP 'inet \K[\d.]+' | head -1)
if [[ -z "$SERVER_IP" ]]; then
    echo "ERROR: Could not detect IPv4 address on $IFACE"
    exit 1
fi
echo "  Server IP:    $SERVER_IP"

# Gateway MAC
GATEWAY_IP=$(ip route show default | awk '/default/ {print $3}' | head -1)
if [[ -z "$GATEWAY_IP" ]]; then
    echo "ERROR: Could not detect default gateway."
    exit 1
fi
ROUTER_MAC=$(ip neigh show "$GATEWAY_IP" dev "$IFACE" | awk '{print $5}' | head -1)
if [[ -z "$ROUTER_MAC" || "$ROUTER_MAC" == "FAILED" ]]; then
    # Trigger ARP resolution
    ping -c 1 -W 1 "$GATEWAY_IP" &>/dev/null || true
    sleep 1
    ROUTER_MAC=$(ip neigh show "$GATEWAY_IP" dev "$IFACE" | awk '{print $5}' | head -1)
fi
if [[ -z "$ROUTER_MAC" || "$ROUTER_MAC" == "FAILED" ]]; then
    echo "ERROR: Could not detect gateway MAC address."
    echo "Manually set it in $CONFIG_FILE after installation."
    ROUTER_MAC="UNKNOWN"
fi
echo "  Gateway IP:   $GATEWAY_IP"
echo "  Gateway MAC:  $ROUTER_MAC"

# Generate KCP key if not provided
if [[ -z "$KCP_KEY" ]]; then
    KCP_KEY=$(openssl rand -hex 16)
    echo "  KCP Key:      $KCP_KEY (auto-generated)"
else
    echo "  KCP Key:      (provided)"
fi

# --- Install dependencies ---
echo ""
echo "Installing dependencies..."
apt install -y libpcap-dev 2>/dev/null || true

# --- Download paqet binary ---
echo "Downloading paqet server..."
mkdir -p "$INSTALL_DIR"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="amd64" ;;
    aarch64) ARCH_SUFFIX="arm64" ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

LATEST_URL=$(curl -sL https://api.github.com/repos/paqet-org/paqet/releases/latest \
    | jq -r ".assets[] | select(.name | contains(\"linux\") and contains(\"${ARCH_SUFFIX}\")) | .browser_download_url" \
    | head -1)

if [[ -z "$LATEST_URL" || "$LATEST_URL" == "null" ]]; then
    echo "WARNING: Could not auto-detect download URL."
    echo "Download paqet manually from: https://github.com/paqet-org/paqet/releases"
    echo "Place binary at: ${INSTALL_DIR}/paqet"
else
    echo "Downloading from: $LATEST_URL"
    curl -Lo "${INSTALL_DIR}/paqet.tar.gz" "$LATEST_URL"
    tar -xzf "${INSTALL_DIR}/paqet.tar.gz" -C "$INSTALL_DIR" 2>/dev/null || true
    rm -f "${INSTALL_DIR}/paqet.tar.gz"
    # Find and rename binary
    PAQET_BIN=$(find "$INSTALL_DIR" -type f -name "paqet*" ! -name "*.yaml*" | head -1)
    if [[ -n "$PAQET_BIN" && "$PAQET_BIN" != "${INSTALL_DIR}/paqet" ]]; then
        mv "$PAQET_BIN" "${INSTALL_DIR}/paqet"
    fi
    chmod +x "${INSTALL_DIR}/paqet"
fi

# --- Generate config ---
echo "Generating config..."
mkdir -p /etc/paqet

sed -e "s/__INTERFACE__/${IFACE}/g" \
    -e "s/__SERVER_IP__/${SERVER_IP}/g" \
    -e "s/__ROUTER_MAC__/${ROUTER_MAC}/g" \
    -e "s/__PORT__/${PORT}/g" \
    -e "s/__KCP_KEY__/${KCP_KEY}/g" \
    "${SCRIPT_DIR}/server.yaml.template" > "$CONFIG_FILE"

chmod 600 "$CONFIG_FILE"
echo "Config written to: $CONFIG_FILE"

# --- iptables rules for pcap ---
echo "Setting up iptables rules for pcap..."
iptables -t raw -C PREROUTING -p tcp --dport "$PORT" -j NOTRACK 2>/dev/null \
    || iptables -t raw -A PREROUTING -p tcp --dport "$PORT" -j NOTRACK
iptables -t raw -C OUTPUT -p tcp --sport "$PORT" -j NOTRACK 2>/dev/null \
    || iptables -t raw -A OUTPUT -p tcp --sport "$PORT" -j NOTRACK
iptables -t mangle -C OUTPUT -p tcp --sport "$PORT" --tcp-flags RST RST -j DROP 2>/dev/null \
    || iptables -t mangle -A OUTPUT -p tcp --sport "$PORT" --tcp-flags RST RST -j DROP

# Make iptables rules persistent
if command -v iptables-save &>/dev/null; then
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
    echo "iptables rules saved."
fi

# --- systemd service ---
cat > /etc/systemd/system/paqet.service << SVCEOF
[Unit]
Description=Paqet Raw Packet Proxy Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/paqet -c ${CONFIG_FILE}
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

# paqet needs raw socket / pcap access
AmbientCapabilities=CAP_NET_RAW CAP_NET_ADMIN
CapabilityBoundingSet=CAP_NET_RAW CAP_NET_ADMIN

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable paqet

echo ""
echo "=========================================="
echo "  Paqet server setup complete!"
echo "=========================================="
echo ""
echo "Config:     $CONFIG_FILE"
echo "Binary:     ${INSTALL_DIR}/paqet"
echo "Service:    paqet.service"
echo ""
echo "Server IP:     $SERVER_IP"
echo "Port:          $PORT"
echo "Interface:     $IFACE"
echo "Gateway MAC:   $ROUTER_MAC"
echo "KCP Key:       $KCP_KEY"
echo ""
echo "IMPORTANT: Save the KCP key! Clients need it to connect."
echo "  Share this key securely with users (not over unencrypted channels)."
echo ""
echo "Start: systemctl start paqet"
echo "Logs:  journalctl -u paqet -f"
echo ""
echo "Client config template:"
echo "  role: client"
echo "  transport:"
echo "    kcp:"
echo "      key: \"$KCP_KEY\""
echo "  # See docs/USER-GUIDE.md for full client config"
