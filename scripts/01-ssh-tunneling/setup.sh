#!/usr/bin/env bash
#
# SSH Tunneling — Server Setup
#
# Configures sshd to allow SOCKS5 tunneling for users in the "tunnelonly" group.
# These users cannot get a shell or do anything except forward TCP traffic.
#
# Usage: sudo bash setup.sh
#
set -euo pipefail

echo "=== SSH Tunneling Setup ==="

# Create tunnelonly group
if ! getent group tunnelonly &>/dev/null; then
    groupadd tunnelonly
    echo "Created group: tunnelonly"
else
    echo "Group 'tunnelonly' already exists."
fi

# Check if Match block already exists
if grep -q "Match Group tunnelonly" /etc/ssh/sshd_config; then
    echo "WARNING: 'Match Group tunnelonly' block already exists in sshd_config."
    echo "Skipping sshd_config modification. Review manually if needed."
else
    # Append Match block to sshd_config
    cat >> /etc/ssh/sshd_config << 'SSHEOF'

# --- Tunnel-only users (added by vpn-server setup) ---
Match Group tunnelonly
    AllowTcpForwarding yes
    AllowStreamLocalForwarding no
    X11Forwarding no
    PermitTTY no
    ForceCommand /bin/false
    MaxSessions 3
    ClientAliveInterval 60
    ClientAliveCountMax 3
SSHEOF
    echo "Added Match Group tunnelonly block to /etc/ssh/sshd_config"
fi

# Validate sshd config before restarting
echo "Validating sshd configuration..."
if sshd -t; then
    echo "Configuration valid. Restarting sshd..."
    systemctl restart sshd
    echo "sshd restarted."
else
    echo "ERROR: sshd configuration is invalid! Fix /etc/ssh/sshd_config manually."
    exit 1
fi

echo ""
echo "SSH tunneling setup complete."
echo "Use add-user.sh to create tunnel-only users."
echo ""
echo "Client connection command:"
echo "  ssh -D 1080 -N -p 22 <username>@<server-ip>"
echo ""
echo "This creates a SOCKS5 proxy on localhost:1080 on the client side."
