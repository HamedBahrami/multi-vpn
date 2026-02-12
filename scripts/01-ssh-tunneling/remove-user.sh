#!/usr/bin/env bash
#
# SSH Tunneling — Remove User
#
# Kills active sessions and deletes the user account.
#
# Usage: sudo bash remove-user.sh <username>
#
set -euo pipefail

USERNAME="${1:-}"

if [[ -z "$USERNAME" ]]; then
    echo "Usage: $0 <username>"
    exit 1
fi

# Verify user exists
if ! id "$USERNAME" &>/dev/null; then
    echo "ERROR: User '$USERNAME' does not exist."
    exit 1
fi

# Safety check: don't delete root or current user
if [[ "$USERNAME" == "root" || "$USERNAME" == "$(whoami)" ]]; then
    echo "ERROR: Cannot remove root or the current user."
    exit 1
fi

# Kill active sessions
echo "Killing active sessions for '$USERNAME'..."
pkill -u "$USERNAME" 2>/dev/null || true
sleep 1
# Force kill if still running
pkill -9 -u "$USERNAME" 2>/dev/null || true

# Delete user and home directory
userdel -r "$USERNAME" 2>/dev/null || userdel "$USERNAME"
echo "User '$USERNAME' deleted."
