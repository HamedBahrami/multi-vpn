#!/usr/bin/env bash
#
# Monitoring & Abuse Prevention — Setup
#
# Configures per-protocol bandwidth tracking and hourly logging.
#
# Usage: sudo bash setup.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Monitoring Setup ==="

# Ensure vnstat is running
systemctl enable vnstat
systemctl start vnstat

# Ensure fail2ban is running
systemctl enable fail2ban
systemctl start fail2ban

# Add fail2ban jail for 3x-ui admin panel (if not already present)
if ! grep -q "x-ui" /etc/fail2ban/jail.local 2>/dev/null; then
    cat >> /etc/fail2ban/jail.local << 'JAILEOF'

[x-ui]
enabled = true
port = 2053
filter = x-ui
maxretry = 5
bantime = 3600
findtime = 600
logpath = /var/log/x-ui/access.log
JAILEOF

    # Create filter for 3x-ui (basic auth failure detection)
    cat > /etc/fail2ban/filter.d/x-ui.conf << 'FILTEREOF'
[Definition]
failregex = ^.*login failed.*from <HOST>.*$
            ^.*authentication failed.*<HOST>.*$
ignoreregex =
FILTEREOF

    systemctl restart fail2ban
    echo "Added fail2ban jail for 3x-ui admin panel."
fi

# Install check-usage.sh to /usr/local/bin
cp "${SCRIPT_DIR}/check-usage.sh" /usr/local/bin/check-usage
chmod +x /usr/local/bin/check-usage
echo "Installed check-usage to /usr/local/bin/check-usage"

# Set up hourly bandwidth logging via cron
CRON_LOG="/var/log/vpn-bandwidth.log"
CRON_CMD="/usr/local/bin/check-usage >> ${CRON_LOG} 2>&1"

# Add cron job (hourly)
if ! crontab -l 2>/dev/null | grep -q "check-usage"; then
    (crontab -l 2>/dev/null; echo "0 * * * * ${CRON_CMD}") | crontab -
    echo "Added hourly bandwidth logging cron job."
else
    echo "Bandwidth logging cron job already exists."
fi

# Set up log rotation
cat > /etc/logrotate.d/vpn-bandwidth << LOGEOF
${CRON_LOG} {
    weekly
    rotate 12
    compress
    missingok
    notifempty
}
LOGEOF

echo ""
echo "=========================================="
echo "  Monitoring setup complete!"
echo "=========================================="
echo ""
echo "Commands:"
echo "  check-usage              — Show current usage report"
echo "  fail2ban-client status   — Show fail2ban jail status"
echo "  vnstat                   — Overall bandwidth stats"
echo "  vnstat -h                — Hourly stats"
echo "  vnstat -d                — Daily stats"
echo ""
echo "Logs:"
echo "  ${CRON_LOG}              — Hourly bandwidth snapshots"
echo "  /var/log/fail2ban.log    — Ban/unban events"
