#!/usr/bin/env bash
#
# check-usage.sh — Per-protocol bandwidth and connection report
#
# Usage: bash check-usage.sh
#
set -euo pipefail

DATE=$(date '+%Y-%m-%d %H:%M:%S UTC')

echo "=== Server Usage Report ==="
echo "Date: $DATE"
echo ""

# --- Overall bandwidth (vnstat) ---
IFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)
if command -v vnstat &>/dev/null && [[ -n "$IFACE" ]]; then
    TODAY_RX=$(vnstat -i "$IFACE" --oneline | cut -d';' -f4 2>/dev/null || echo "N/A")
    TODAY_TX=$(vnstat -i "$IFACE" --oneline | cut -d';' -f5 2>/dev/null || echo "N/A")
    MONTH_RX=$(vnstat -i "$IFACE" --oneline | cut -d';' -f9 2>/dev/null || echo "N/A")
    MONTH_TX=$(vnstat -i "$IFACE" --oneline | cut -d';' -f10 2>/dev/null || echo "N/A")
else
    TODAY_RX="N/A"; TODAY_TX="N/A"; MONTH_RX="N/A"; MONTH_TX="N/A"
fi

# --- SSH tunneling ---
SSH_TUNNEL_USERS=$(who | grep -c "tunnelonly" 2>/dev/null || echo "0")
# Count SSH tunnel connections (SOCKS5 forwarding)
SSH_CONNECTIONS=$(ss -tnp 2>/dev/null | grep -c "sshd" || echo "0")

# --- 3x-ui / VLESS (port 443) ---
VLESS_CONNECTIONS=$(ss -tnp 2>/dev/null | grep ":443 " | grep -cv "LISTEN" || echo "0")
XRAY_STATUS="stopped"
if systemctl is-active --quiet x-ui 2>/dev/null; then
    XRAY_STATUS="running"
fi

# --- TrustTunnel (port 8443) ---
TT_CONNECTIONS=$(ss -tnp 2>/dev/null | grep ":8443 " | grep -cv "LISTEN" || echo "0")
TT_STATUS="stopped"
if systemctl is-active --quiet trusttunnel 2>/dev/null; then
    TT_STATUS="running"
fi

# --- Paqet (port 9999) ---
PAQET_STATUS="stopped"
if systemctl is-active --quiet paqet 2>/dev/null; then
    PAQET_STATUS="running"
fi
# paqet uses raw sockets, so ss won't show its connections
# Check if process is running and has open pcap handles
PAQET_PID=$(pgrep -x paqet 2>/dev/null || echo "")

# --- Tailscale ---
TS_STATUS="stopped"
TS_PEERS=0
if command -v tailscale &>/dev/null; then
    if tailscale status &>/dev/null; then
        TS_STATUS="running"
        TS_PEERS=$(tailscale status 2>/dev/null | grep -c "active" || echo "0")
    fi
fi

# --- Total connections ---
TOTAL_CONN=$((SSH_CONNECTIONS + VLESS_CONNECTIONS + TT_CONNECTIONS + TS_PEERS))

# --- Print report ---
printf "%-20s %-12s %s\n" "Protocol" "Status" "Details"
printf "%-20s %-12s %s\n" "--------" "------" "-------"
printf "%-20s %-12s tunnel users: %s, SSH conns: %s\n" "SSH Tunneling" "active" "$SSH_TUNNEL_USERS" "$SSH_CONNECTIONS"
printf "%-20s %-12s connections: %s (use 3x-ui panel for per-user stats)\n" "VLESS (3x-ui)" "$XRAY_STATUS" "$VLESS_CONNECTIONS"
printf "%-20s %-12s connections: %s\n" "TrustTunnel" "$TT_STATUS" "$TT_CONNECTIONS"
printf "%-20s %-12s pid: %s\n" "Paqet" "$PAQET_STATUS" "${PAQET_PID:-N/A}"
printf "%-20s %-12s peers: %s\n" "Tailscale" "$TS_STATUS" "$TS_PEERS"

echo ""
echo "Bandwidth ($IFACE):"
printf "  Today:      RX %s / TX %s\n" "$TODAY_RX" "$TODAY_TX"
printf "  This month: RX %s / TX %s\n" "$MONTH_RX" "$MONTH_TX"
echo ""
echo "Estimated active connections: $TOTAL_CONN"

# --- System resources ---
echo ""
echo "System:"
printf "  CPU:    %s\n" "$(top -bn1 | grep 'Cpu(s)' | awk '{printf "%.1f%% used", 100-$8}')"
printf "  RAM:    %s\n" "$(free -h | awk '/^Mem:/{printf "%s / %s (%.0f%%)", $3, $2, $3/$2*100}')"
printf "  Disk:   %s\n" "$(df -h / | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}')"
LOAD=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
printf "  Load:   %s\n" "$LOAD"
echo ""

# --- fail2ban ---
BANNED=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}' || echo "N/A")
echo "fail2ban: $BANNED IPs currently banned (SSH)"
echo ""
