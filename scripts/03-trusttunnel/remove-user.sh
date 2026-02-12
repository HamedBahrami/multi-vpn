#!/usr/bin/env bash
#
# TrustTunnel — Remove User
#
# Removes a user block from the TrustTunnel credentials file.
#
# Usage: sudo bash remove-user.sh <username>
#
set -euo pipefail

USERNAME="${1:-}"
CREDS_FILE="/etc/trusttunnel/credentials.toml"

if [[ -z "$USERNAME" ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

if [[ ! -f "$CREDS_FILE" ]]; then
    echo "ERROR: Credentials file not found: $CREDS_FILE"
    exit 1
fi

# Check user exists
if ! grep -q "username = \"${USERNAME}\"" "$CREDS_FILE"; then
    echo "ERROR: User '$USERNAME' not found in $CREDS_FILE"
    exit 1
fi

# Remove the [[client]] block for this user
# The block is: [[client]]\nusername = "..."\npassword = "..."
# We use awk to skip the matching block
awk -v user="$USERNAME" '
    /^\[\[client\]\]/ {
        block = $0 "\n"
        getline; block = block $0 "\n"
        if ($0 ~ "username = \"" user "\"") {
            getline  # skip password line
            next
        } else {
            printf "%s", block
        }
        next
    }
    { print }
' "$CREDS_FILE" > "${CREDS_FILE}.tmp"

mv "${CREDS_FILE}.tmp" "$CREDS_FILE"
chmod 600 "$CREDS_FILE"

echo "User '$USERNAME' removed from TrustTunnel."

# Reload service if running
if systemctl is-active --quiet trusttunnel; then
    systemctl reload trusttunnel 2>/dev/null || systemctl restart trusttunnel
    echo "TrustTunnel service reloaded."
fi
