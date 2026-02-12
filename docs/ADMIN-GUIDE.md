# Admin Guide — Multi-Protocol VPN Server

## Port Allocation

| Port | Protocol | Transport |
|------|----------|-----------|
| 22 | SSH | TCP — tunneling + admin |
| 443 | VLESS Reality | TCP — 3x-ui managed |
| 2053 | 3x-ui admin panel | TCP — restrict to admin IP |
| 8443 | TrustTunnel | TCP + UDP (QUIC) |
| 9999 | Paqet | Raw packets (pcap) |
| 41641 | Tailscale | UDP (WireGuard) |

---

## User Management

### SSH Tunneling

```bash
# Add user
sudo bash /root/vpn-server/scripts/01-ssh-tunneling/add-user.sh alice 'P@ssw0rd'

# Remove user
sudo bash /root/vpn-server/scripts/01-ssh-tunneling/remove-user.sh alice

# List tunnel users
getent group tunnelonly

# See active SSH sessions
who | grep tunnelonly
ss -tnp | grep sshd
```

### VLESS (3x-ui)

Managed through the web panel at `https://<server-ip>:2053`.

```bash
# Restart 3x-ui
systemctl restart x-ui

# View logs
journalctl -u x-ui -f

# Reset admin password
x-ui reset
```

Per-user management:
- **Add user:** Panel > Inbounds > expand > Add Client
- **Remove user:** Panel > Inbounds > expand > delete client
- **Set limits:** IP limit (devices), traffic limit, expiry date
- **Get link:** Click QR icon next to user name

### TrustTunnel

```bash
# Add user
sudo bash /root/vpn-server/scripts/03-trusttunnel/add-user.sh bob 'S3cureP@ss'

# Remove user
sudo bash /root/vpn-server/scripts/03-trusttunnel/remove-user.sh bob

# List users
grep 'username' /etc/trusttunnel/credentials.toml

# Restart
systemctl restart trusttunnel
journalctl -u trusttunnel -f
```

### Paqet

Paqet has no per-user management. All clients share a single KCP key.

```bash
# View current key
grep 'key:' /etc/paqet/server.yaml

# Rotate key (all clients must update!)
NEW_KEY=$(openssl rand -hex 16)
sed -i "s/key: \".*\"/key: \"${NEW_KEY}\"/" /etc/paqet/server.yaml
systemctl restart paqet
echo "New key: $NEW_KEY"

# Check status
systemctl status paqet
journalctl -u paqet -f
```

### Tailscale

Managed through the Tailscale admin console at https://login.tailscale.com/admin.

```bash
# Check connected peers
tailscale status

# View exit node usage
tailscale status --json | jq '.Peer[] | select(.ExitNode==true)'

# Restart
systemctl restart tailscaled
```

User management:
- **Add user:** Send tailnet invite link from admin console
- **Remove user:** Remove from tailnet in admin console
- **Restrict access:** Edit ACLs at login.tailscale.com/admin/acls

---

## Monitoring

### Quick Status

```bash
# All-in-one report
check-usage

# Service status
systemctl status x-ui trusttunnel paqet tailscaled sshd

# Active connections by port
ss -tnp | grep -E ':(22|443|2053|8443|9999) ' | wc -l
```

### Bandwidth

```bash
# Today's usage
vnstat -d 1

# This month
vnstat -m 1

# Real-time monitoring
vnstat -l

# Per-hour breakdown
vnstat -h
```

### fail2ban

```bash
# Status
fail2ban-client status
fail2ban-client status sshd

# Unban an IP
fail2ban-client set sshd unbanip <ip-address>

# View ban log
tail -50 /var/log/fail2ban.log
```

---

## Common Maintenance Tasks

### Update 3x-ui

```bash
# Backup current config
cp /etc/x-ui/x-ui.db /etc/x-ui/x-ui.db.bak

# Update
bash <(curl -Ls https://raw.githubusercontent.com/MHSanaei/3x-ui/master/install.sh)
```

### Update TrustTunnel

```bash
systemctl stop trusttunnel
# Download new binary to /opt/trusttunnel/
# (see scripts/03-trusttunnel/setup.sh for download steps)
systemctl start trusttunnel
```

### Update Paqet

```bash
systemctl stop paqet
# Download new binary to /opt/paqet/
# (see scripts/04-paqet/setup.sh for download steps)
systemctl start paqet
```

### Restrict 3x-ui Panel to Admin IP

```bash
# Remove public access
ufw delete allow 2053/tcp

# Allow only your IP
ufw allow from <your-ip> to any port 2053 proto tcp

# If your IP changes, update the rule
ufw delete allow from <old-ip> to any port 2053 proto tcp
ufw allow from <new-ip> to any port 2053 proto tcp
```

### Check if Server IP is Blocked

From inside Iran:
```bash
# TCP connectivity
curl -v --connect-timeout 5 https://<server-ip>:443

# Ping (may be blocked independently)
ping -c 3 <server-ip>

# Port scan
nmap -Pn -p 22,443,8443 <server-ip>
```

If blocked, contact VPS provider for IP change.

### Emergency: Rotate All Credentials

If you suspect credentials are compromised:

```bash
# 1. SSH — change all tunnel user passwords
for user in $(getent group tunnelonly | cut -d: -f4 | tr ',' ' '); do
    NEW_PASS=$(openssl rand -base64 12)
    echo "${user}:${NEW_PASS}" | chpasswd
    echo "User $user new password: $NEW_PASS"
done

# 2. VLESS — regenerate client UUIDs in 3x-ui panel
echo "Log into 3x-ui panel and regenerate client UUIDs"

# 3. TrustTunnel — reset all passwords
echo "Edit /etc/trusttunnel/credentials.toml with new passwords"
systemctl restart trusttunnel

# 4. Paqet — rotate KCP key
NEW_KEY=$(openssl rand -hex 16)
sed -i "s/key: \".*\"/key: \"${NEW_KEY}\"/" /etc/paqet/server.yaml
systemctl restart paqet
echo "New paqet key: $NEW_KEY"

# 5. Tailscale — remove compromised devices from admin console
echo "Remove devices at https://login.tailscale.com/admin/machines"
```

---

## Troubleshooting

### 3x-ui panel not accessible
```bash
systemctl status x-ui
ss -tlnp | grep 2053
ufw status | grep 2053
journalctl -u x-ui --since "10 min ago"
```

### VLESS Reality not connecting
```bash
# Check Xray is listening on 443
ss -tlnp | grep 443

# Test Reality handshake (from another server)
curl -v --resolve www.google.com:443:<server-ip> https://www.google.com

# Check logs
journalctl -u x-ui -f
```

### TrustTunnel not starting
```bash
# Check TLS config
cat /etc/trusttunnel/config.toml

# Check port conflict with VLESS (both on 443?)
ss -tlnp | grep -E ':(443|8443) '

# Logs
journalctl -u trusttunnel -f
```

### Paqet not working
```bash
# Check iptables rules exist
iptables -t raw -L -n | grep 9999
iptables -t mangle -L -n | grep 9999

# Check pcap is working
tcpdump -i <interface> port 9999 -c 5

# Logs
journalctl -u paqet -f
```

### High CPU / Memory
```bash
htop
# Identify which service is consuming resources

# Check for abuse (excessive connections)
ss -tnp | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -20

# If a single IP is abusing, block it
ufw deny from <abusive-ip>
```

### Disk full
```bash
df -h
du -sh /var/log/* | sort -rh | head -10

# Clean old logs
journalctl --vacuum-time=7d
apt clean
```
