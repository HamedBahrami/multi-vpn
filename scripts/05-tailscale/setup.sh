#!/usr/bin/env bash
#
# Tailscale — Exit Node Setup
#
# Installs Tailscale and configures the server as an exit node.
# Users join the tailnet and select this server as their exit node.
#
# Usage: sudo bash setup.sh
#
# Prerequisites:
#   - IP forwarding enabled (done by 00-initial-setup.sh)
#   - Port 41641/udp open (done by 00-initial-setup.sh)
#
set -euo pipefail

echo "=== Tailscale Exit Node Setup ==="

# Check IP forwarding
if [[ $(sysctl -n net.ipv4.ip_forward) != "1" ]]; then
    echo "WARNING: IP forwarding not enabled. Enabling..."
    sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-vpn-server.conf
    sysctl --system
fi

# Install Tailscale
if command -v tailscale &>/dev/null; then
    echo "Tailscale already installed: $(tailscale version)"
else
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Start Tailscale as exit node
echo ""
echo "Starting Tailscale as exit node..."
echo "This will open a browser or print an auth URL."
echo ""

tailscale up --advertise-exit-node --ssh

echo ""
echo "=========================================="
echo "  Tailscale setup complete!"
echo "=========================================="
echo ""
echo "IMPORTANT — Manual steps required:"
echo ""
echo "1. Approve the exit node in Tailscale admin console:"
echo "   https://login.tailscale.com/admin/machines"
echo "   Find this server > Edit route settings > Enable 'Use as exit node'"
echo ""
echo "2. Invite users to your tailnet:"
echo "   https://login.tailscale.com/admin/users"
echo "   Share the invite link with each user (1-3 people)"
echo ""
echo "3. (Optional) Set up ACLs to restrict access:"
echo "   https://login.tailscale.com/admin/acls"
echo "   Recommended: Allow exit node usage but deny direct SSH via Tailscale"
echo ""
echo "User setup:"
echo "  1. Install Tailscale app on device"
echo "  2. Log in to the tailnet"
echo "  3. Enable exit node: select this server"
echo "  4. All traffic now routes through the VPS"
echo ""
echo "Tailscale free tier: 3 users, 100 devices."
echo "For 1-3 people with up to 3 devices each, free tier is sufficient."
echo ""
echo "Status: tailscale status"
echo "Logs:   journalctl -u tailscaled -f"
