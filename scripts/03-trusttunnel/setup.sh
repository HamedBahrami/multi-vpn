#!/usr/bin/env bash
#
# TrustTunnel — Server Setup
#
# Downloads and installs TrustTunnel server.
# TrustTunnel uses HTTP/2 + QUIC to tunnel traffic, mimicking normal HTTPS.
#
# Usage: sudo bash setup.sh [port]
#   port: Listen port (default: 8443)
#
# Prerequisites:
#   - A domain name pointing to this server (for TLS cert) — OR use self-signed
#   - Port 8443 open in UFW (done by 00-initial-setup.sh)
#
set -euo pipefail

PORT="${1:-8443}"
INSTALL_DIR="/opt/trusttunnel"
CONFIG_DIR="/etc/trusttunnel"
CREDS_FILE="${CONFIG_DIR}/credentials.toml"

echo "=== TrustTunnel Server Setup ==="
echo "Port: $PORT"
echo ""

# Create directories
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH_SUFFIX="amd64" ;;
    aarch64) ARCH_SUFFIX="arm64" ;;
    *)
        echo "ERROR: Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Download latest TrustTunnel
echo "Downloading TrustTunnel (${ARCH_SUFFIX})..."
LATEST_URL=$(curl -sL https://api.github.com/repos/nickolaev/trusttunnel/releases/latest \
    | jq -r ".assets[] | select(.name | contains(\"linux-${ARCH_SUFFIX}\")) | .browser_download_url" \
    | head -1)

if [[ -z "$LATEST_URL" || "$LATEST_URL" == "null" ]]; then
    echo "WARNING: Could not auto-detect download URL from GitHub."
    echo "Please download TrustTunnel manually:"
    echo "  https://github.com/nickolaev/trusttunnel/releases"
    echo ""
    echo "Place the binary at: ${INSTALL_DIR}/trusttunnel-server"
    echo "Then re-run this script."
    echo ""
    echo "Continuing with configuration..."
else
    echo "Downloading from: $LATEST_URL"
    curl -Lo "${INSTALL_DIR}/trusttunnel-server.tar.gz" "$LATEST_URL"
    tar -xzf "${INSTALL_DIR}/trusttunnel-server.tar.gz" -C "$INSTALL_DIR" 2>/dev/null \
        || unzip -o "${INSTALL_DIR}/trusttunnel-server.tar.gz" -d "$INSTALL_DIR" 2>/dev/null \
        || mv "${INSTALL_DIR}/trusttunnel-server.tar.gz" "${INSTALL_DIR}/trusttunnel-server"
    chmod +x "${INSTALL_DIR}/trusttunnel-server" 2>/dev/null || true
    # Find the actual binary
    find "$INSTALL_DIR" -type f -executable -name "*trusttunnel*" | head -1
    echo "Download complete."
fi

# Initialize credentials file
if [[ ! -f "$CREDS_FILE" ]]; then
    cat > "$CREDS_FILE" << 'CREDEOF'
# TrustTunnel user credentials
# Add users with add-user.sh or manually below.
#
# Format:
# [[client]]
# username = "alice"
# password = "secure-password-here"
CREDEOF
    chmod 600 "$CREDS_FILE"
    echo "Created credentials file: $CREDS_FILE"
else
    echo "Credentials file already exists: $CREDS_FILE"
fi

# Create server config
cat > "${CONFIG_DIR}/config.toml" << CONFEOF
[server]
listen_addr = "0.0.0.0:${PORT}"
credentials_file = "${CREDS_FILE}"

# TLS configuration
# Option A: Let's Encrypt (requires domain)
# [tls]
# mode = "acme"
# domain = "your-domain.com"
# email = "admin@your-domain.com"

# Option B: Self-signed (no domain required)
[tls]
mode = "self-signed"
CONFEOF

echo "Created config: ${CONFIG_DIR}/config.toml"
echo ""
echo "NOTE: Edit ${CONFIG_DIR}/config.toml to configure TLS."
echo "  - If you have a domain, uncomment the ACME section and fill in your domain."
echo "  - Otherwise, self-signed mode works but clients need to accept the cert."

# Create systemd service
cat > /etc/systemd/system/trusttunnel.service << SVCEOF
[Unit]
Description=TrustTunnel VPN Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${INSTALL_DIR}/trusttunnel-server --config ${CONFIG_DIR}/config.toml
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${CONFIG_DIR}
PrivateTmp=true

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable trusttunnel

echo ""
echo "=========================================="
echo "  TrustTunnel setup complete!"
echo "=========================================="
echo ""
echo "Config:       ${CONFIG_DIR}/config.toml"
echo "Credentials:  ${CREDS_FILE}"
echo "Service:      trusttunnel.service"
echo ""
echo "Next steps:"
echo "  1. Edit config.toml for TLS settings (domain or self-signed)"
echo "  2. Add users: bash add-user.sh <username> <password>"
echo "  3. Start service: systemctl start trusttunnel"
echo "  4. Check status: systemctl status trusttunnel"
echo "  5. View logs: journalctl -u trusttunnel -f"
