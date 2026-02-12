#!/usr/bin/env bash
#
# 3x-ui Panel — Installation
#
# Installs 3x-ui (Xray management panel) for VLESS + Reality protocol.
# After installation, follow post-install.md for web panel configuration.
#
# Usage: sudo bash setup.sh [admin-port]
#   admin-port: Panel port (default: 2053)
#
set -euo pipefail

PANEL_PORT="${1:-2053}"

echo "=== 3x-ui Panel Installation ==="
echo "Admin panel port: $PANEL_PORT"
echo ""

# Check if already installed
if systemctl is-active --quiet x-ui 2>/dev/null; then
    echo "WARNING: 3x-ui is already running."
    echo "To reinstall, first stop it: systemctl stop x-ui"
    echo "Then run this script again."
    exit 1
fi

# Install 3x-ui using official installer
echo "Installing 3x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)

# The installer is interactive and will ask for:
# - Username (set a strong admin username)
# - Password (set a strong admin password)
# - Panel port (enter the desired port, e.g., 2053)
#
# After installation, the installer prints the admin URL.

echo ""
echo "=========================================="
echo "  3x-ui installed!"
echo "=========================================="
echo ""
echo "Admin panel: https://<server-ip>:${PANEL_PORT}"
echo ""
echo "IMPORTANT: Follow scripts/02-3xui/post-install.md for:"
echo "  1. VLESS + Reality inbound setup"
echo "  2. User creation with IP/traffic limits"
echo "  3. Subscription link generation"
echo ""
echo "Security recommendations:"
echo "  - Change default panel port if you haven't already"
echo "  - Set a strong admin password"
echo "  - Enable panel TLS (Settings > Panel > Enable HTTPS)"
echo "  - Restrict panel access to your admin IP via UFW:"
echo "    ufw delete allow 2053/tcp"
echo "    ufw allow from <your-ip> to any port 2053 proto tcp"
