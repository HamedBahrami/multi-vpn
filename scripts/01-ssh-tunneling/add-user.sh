#!/usr/bin/env bash
#
# SSH Tunneling — Add User
#
# Creates a tunnel-only user who can only use SSH for SOCKS5 forwarding.
# No shell access, no file transfer, no port forwarding beyond TCP.
#
# Usage: sudo bash add-user.sh <username> <password>
#
set -euo pipefail

USERNAME="${1:-}"
PASSWORD="${2:-}"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "Usage: $0 <username> <password>"
    echo "Example: $0 alice 'S3cureP@ss'"
    exit 1
fi

# Validate username
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]]; then
    echo "ERROR: Invalid username. Use lowercase letters, numbers, hyphens, underscores."
    exit 1
fi

# Check if user exists
if id "$USERNAME" &>/dev/null; then
    echo "ERROR: User '$USERNAME' already exists."
    exit 1
fi

# Check if tunnelonly group exists
if ! getent group tunnelonly &>/dev/null; then
    echo "ERROR: Group 'tunnelonly' does not exist. Run setup.sh first."
    exit 1
fi

# Create user
useradd -m -s /bin/false -G tunnelonly "$USERNAME"
echo "${USERNAME}:${PASSWORD}" | chpasswd

echo "User '$USERNAME' created and added to tunnelonly group."
echo ""
echo "=== Connection Details ==="
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server:   $SERVER_IP"
echo "Port:     22"
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo ""
echo "Client commands:"
echo "  # SOCKS5 proxy on localhost:1080"
echo "  ssh -D 1080 -N -p 22 ${USERNAME}@${SERVER_IP}"
echo ""
echo "  # With keep-alive and background"
echo "  ssh -D 1080 -N -f -o ServerAliveInterval=60 -p 22 ${USERNAME}@${SERVER_IP}"
echo ""
echo "Android (Matsuri/HTTP Injector):"
echo "  Type: SSH"
echo "  Host: $SERVER_IP"
echo "  Port: 22"
echo "  Username: $USERNAME"
echo "  Password: $PASSWORD"
echo "  Enable SOCKS5 proxy on port 1080"
