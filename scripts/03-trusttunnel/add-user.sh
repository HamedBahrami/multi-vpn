#!/usr/bin/env bash
#
# TrustTunnel — Add User
#
# Appends a new user to the TrustTunnel credentials file.
#
# Usage: sudo bash add-user.sh <username> <password>
#
set -euo pipefail

USERNAME="${1:-}"
PASSWORD="${2:-}"
CREDS_FILE="/etc/trusttunnel/credentials.toml"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "Usage: $0 <username> <password>"
    echo "Example: $0 alice 'S3cureP@ss'"
    exit 1
fi

if [[ ! -f "$CREDS_FILE" ]]; then
    echo "ERROR: Credentials file not found: $CREDS_FILE"
    echo "Run setup.sh first."
    exit 1
fi

# Check if user already exists
if grep -q "username = \"${USERNAME}\"" "$CREDS_FILE"; then
    echo "ERROR: User '$USERNAME' already exists in $CREDS_FILE"
    exit 1
fi

# Append user
cat >> "$CREDS_FILE" << USEREOF

[[client]]
username = "${USERNAME}"
password = "${PASSWORD}"
USEREOF

echo "User '$USERNAME' added to TrustTunnel."

# Reload service if running
if systemctl is-active --quiet trusttunnel; then
    systemctl reload trusttunnel 2>/dev/null || systemctl restart trusttunnel
    echo "TrustTunnel service reloaded."
fi

echo ""
echo "=== Connection Details ==="
SERVER_IP=$(hostname -I | awk '{print $1}')
PORT=$(grep -oP 'listen_addr\s*=\s*"[^:]+:\K[0-9]+' /etc/trusttunnel/config.toml 2>/dev/null || echo "8443")
echo "Server:   $SERVER_IP"
echo "Port:     $PORT"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo ""
echo "Client setup: see docs/USER-GUIDE.md for TrustTunnel section."
