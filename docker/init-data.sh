#!/usr/bin/env bash
#
# Initialize Docker volume directories with default configs.
# Run once before first `docker compose up`.
#
# Usage: bash init-data.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/data"

echo "=== Initializing Docker data directories ==="

# 3x-ui
mkdir -p "${DATA_DIR}/3xui/db" "${DATA_DIR}/3xui/certs"
echo "Created 3xui data dirs."

# TrustTunnel
mkdir -p "${DATA_DIR}/trusttunnel"

if [[ ! -f "${DATA_DIR}/trusttunnel/config.toml" ]]; then
    cat > "${DATA_DIR}/trusttunnel/config.toml" << 'EOF'
[server]
listen_addr = "0.0.0.0:8443"
credentials_file = "/etc/trusttunnel/credentials.toml"

# TLS: self-signed (no domain required)
# To use Let's Encrypt, uncomment the acme section and comment out self-signed.
[tls]
mode = "self-signed"

# [tls]
# mode = "acme"
# domain = "your-domain.com"
# email = "admin@your-domain.com"
EOF
    echo "Created TrustTunnel config."
else
    echo "TrustTunnel config already exists, skipping."
fi

if [[ ! -f "${DATA_DIR}/trusttunnel/credentials.toml" ]]; then
    cat > "${DATA_DIR}/trusttunnel/credentials.toml" << 'EOF'
# TrustTunnel user credentials
# Add users below, then restart the container:
#   docker compose restart trusttunnel
#
# [[client]]
# username = "alice"
# password = "secure-password"
EOF
    chmod 600 "${DATA_DIR}/trusttunnel/credentials.toml"
    echo "Created TrustTunnel credentials file."
else
    echo "TrustTunnel credentials already exist, skipping."
fi

echo ""
echo "Done. Data directory:"
find "${DATA_DIR}" -type f | sort
echo ""
echo "Next: docker compose up -d"
