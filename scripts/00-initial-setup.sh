#!/usr/bin/env bash
#
# 00-initial-setup.sh — OS hardening, base packages, firewall, sysctl tuning
#
# Usage: sudo bash 00-initial-setup.sh <interface-name>
# Example: sudo bash 00-initial-setup.sh ens3
#
set -euo pipefail

# --- Arguments ---
IFACE="${1:-}"
if [[ -z "$IFACE" ]]; then
    echo "Usage: $0 <server-interface>"
    echo "Example: $0 ens3"
    echo ""
    echo "Available interfaces:"
    ip -br link show | grep -v lo
    exit 1
fi

# Verify interface exists
if ! ip link show "$IFACE" &>/dev/null; then
    echo "ERROR: Interface '$IFACE' not found."
    ip -br link show | grep -v lo
    exit 1
fi

echo "=== Multi-Protocol VPN Server — Initial Setup ==="
echo "Interface: $IFACE"
echo ""

# --- System Update ---
echo "[1/9] Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y

# --- Essential Packages ---
echo "[2/9] Installing essential packages..."
apt install -y \
    curl wget unzip jq \
    vnstat fail2ban ufw \
    htop iotop \
    net-tools \
    libpcap-dev \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg

# --- UFW Firewall ---
echo "[3/9] Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp comment "SSH"

# VLESS Reality (3x-ui)
ufw allow 443/tcp comment "VLESS Reality"

# TrustTunnel
ufw allow 8443/tcp comment "TrustTunnel HTTP/2"
ufw allow 8443/udp comment "TrustTunnel QUIC"

# Paqet
ufw allow 9999/udp comment "Paqet raw packets"

# Tailscale WireGuard
ufw allow 41641/udp comment "Tailscale"

# 3x-ui admin panel (restrict to admin IP later)
ufw allow 2053/tcp comment "3x-ui admin panel"

ufw --force enable
echo "UFW status:"
ufw status verbose

# --- fail2ban ---
echo "[4/9] Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << 'JAILEOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
maxretry = 5
bantime = 3600

[sshd-ddos]
enabled = true
port = ssh
filter = sshd-ddos
maxretry = 10
bantime = 7200
JAILEOF

systemctl enable fail2ban
systemctl restart fail2ban

# --- vnstat ---
echo "[5/9] Enabling vnstat for bandwidth monitoring..."
systemctl enable vnstat
systemctl start vnstat
# Initialize database for main interface
vnstat -i "$IFACE" --add 2>/dev/null || true

# --- sysctl tuning ---
echo "[6/9] Applying sysctl tuning..."
cat > /etc/sysctl.d/99-vpn-server.conf << 'SYSEOF'
# TCP performance
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 4096
net.core.netdev_max_backlog = 4096

# BBR congestion control
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP keepalive (shorter for tunnel detection)
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# Connection tracking (for many concurrent connections)
net.netfilter.nf_conntrack_max = 131072

# IP forwarding (needed for Tailscale exit node, VPN routing)
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Reduce TIME_WAIT
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# Buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
SYSEOF

sysctl --system

# --- Swap ---
echo "[7/9] Checking swap..."
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
if [[ "$TOTAL_RAM_MB" -lt 4096 ]]; then
    if ! swapon --show | grep -q /swapfile; then
        echo "RAM is ${TOTAL_RAM_MB}MB (<4GB), creating 2GB swap..."
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        echo "Swap enabled."
    else
        echo "Swap already exists."
    fi
else
    echo "RAM is ${TOTAL_RAM_MB}MB (>=4GB), skipping swap."
fi

# --- Timezone ---
echo "[8/9] Setting timezone to UTC..."
timedatectl set-timezone UTC

# --- Unattended Upgrades ---
echo "[9/9] Enabling unattended security upgrades..."
apt install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades << 'AUTOEOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
AUTOEOF

# Ensure only security updates are auto-applied (default on Ubuntu, but be explicit)
dpkg-reconfigure -plow unattended-upgrades 2>/dev/null || true

# --- Summary ---
echo ""
echo "=========================================="
echo "  Initial setup complete!"
echo "=========================================="
echo ""
echo "Interface:     $IFACE"
echo "Firewall:      UFW enabled"
echo "  Open ports:  22/tcp, 443/tcp, 8443/tcp+udp, 9999/udp, 41641/udp, 2053/tcp"
echo "fail2ban:      SSH jail active (ban 1h, max 5 retries)"
echo "vnstat:        Tracking $IFACE"
echo "BBR:           Enabled"
echo "IP forwarding: Enabled"
echo "Swap:          $(swapon --show --noheadings | wc -l) swap file(s) active"
echo "Timezone:      UTC"
echo "Auto-updates:  Security patches enabled"
echo ""
echo "Next steps:"
echo "  1. Run scripts/01-ssh-tunneling/setup.sh"
echo "  2. Run scripts/02-3xui/setup.sh"
echo "  3. Run scripts/03-trusttunnel/setup.sh"
echo "  4. Run scripts/04-paqet/setup.sh $IFACE"
echo "  5. Run scripts/05-tailscale/setup.sh"
echo "  6. Run scripts/06-monitoring/setup.sh"
