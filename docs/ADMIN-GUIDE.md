# Admin Guide — Multi-Protocol VPN Server

## Port Allocation

| Port | Protocol | Transport | Notes |
|------|----------|-----------|-------|
| 22 | SSH | TCP | Tunneling + admin |
| 443 | VLESS Reality OR VLESS+WS+CF | TCP | 3x-ui managed; pick one or move CF-fronted version off 443 |
| 2053 | 3x-ui admin panel | TCP | Restrict to admin IP via UFW; CF-supported port too |
| 2087, 2096 | Optional alt-HTTPS for fronted inbounds | TCP/UDP | All in CF Free's supported HTTPS port list |
| 8443 | TrustTunnel | TCP + UDP (QUIC) | CF-supported port |
| 9999 | Paqet | Raw packets (pcap) | Increasingly DPI-detected in 2025 |
| (varies) | Hysteria2 | UDP | Separate `hysteria-server` binary (not xray). UDP/QUIC pattern; whether it survives DPI depends on the network. |
| 41641 | Tailscale | UDP (WireGuard) | Often whitelisted by ISPs that block other UDP |

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

## Adding Hysteria2 (not via xray/3x-ui)

xray-core does NOT implement Hysteria2 — `xray-linux-amd64` rejects the inbound with `unknown config id: hysteria2`. Hysteria2 needs the separate `hysteria-server` binary from the `apernet/hysteria` project.

```bash
# install (creates /usr/local/bin/hysteria + /etc/hysteria/config.yaml + systemd unit)
curl -fsSL https://get.hy2.sh/ | bash
```

The default systemd unit runs as user `hysteria`, not root, so cert files in `/etc/x-ui/cert` (which are root-owned) won't be readable. Put dedicated copies in `/etc/hysteria/` with the right ownership:

```bash
cp /etc/letsencrypt/live/<domain>/fullchain.pem /etc/hysteria/cert.crt
cp /etc/letsencrypt/live/<domain>/privkey.pem   /etc/hysteria/cert.key
chown hysteria:hysteria /etc/hysteria/cert.*
chmod 644 /etc/hysteria/cert.crt
chmod 640 /etc/hysteria/cert.key
```

Minimal `config.yaml`:
```yaml
listen: :2096               # or any UDP port; CF-supported HTTPS ports are 443/2053/2083/2087/2096/8443

tls:
  cert: /etc/hysteria/cert.crt
  key: /etc/hysteria/cert.key

obfs:
  type: salamander          # disguises QUIC pattern
  salamander:
    password: <random-22-char-string>

auth:
  type: password
  password: <random-22-char-string>

masquerade:                 # serve fake HTTPS to probes
  type: proxy
  proxy:
    url: https://www.bing.com/
    rewriteHost: true
```

Add a deploy-hook to keep certs in sync when LE renews:
```bash
mkdir -p /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/copy-to-services.sh <<'EOF'
#!/bin/bash
SRC=/etc/letsencrypt/live/<domain>
cp "$SRC/fullchain.pem" /etc/hysteria/cert.crt
cp "$SRC/privkey.pem"   /etc/hysteria/cert.key
chown hysteria:hysteria /etc/hysteria/cert.*
systemctl restart hysteria-server
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/copy-to-services.sh
```

Client URI (Hiddify Next has the cleanest hy2 support; v2rayNG parses it in newer versions):
```
hysteria2://<auth-password>@<domain>:2096?sni=<domain>&obfs=salamander&obfs-password=<obfs-password>#<remark>
```

#### When Hysteria2 doesn't connect through restrictive networks

Some ISPs block all UDP except WireGuard-pattern (the only thing Tailscale/WG sends). Symptoms: client says "Connected" but no traffic flows, server logs are empty, `tcpdump -i ens3 "udp port <port>"` shows 0 inbound packets. You can verify the server is healthy with a loopback test:

```bash
cat > /tmp/hy-client.yaml <<EOF
server: 127.0.0.1:<port>
auth: <auth-password>
tls: { sni: <domain>, ca: /etc/letsencrypt/live/<domain>/chain.pem }
obfs: { type: salamander, salamander: { password: <obfs-password> } }
socks5: { listen: 127.0.0.1:11081 }
EOF
hysteria client -c /tmp/hy-client.yaml &
curl -x socks5h://127.0.0.1:11081 https://1.1.1.1     # 200/301 = server works
```

If loopback works but real clients can't reach it: it's the network, not the config — switch users to Cloudflare-fronted VLESS+WS or just keep them on Trojan/Tailscale.

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

#### Symptom: TCP connects but TLS handshake stalls (Reality response not ACKed)
Check `ss -tn state established '( dport = :443 )'` — if you see large `Send-Q` values on connections to clients, the server is sending the Reality response but the client side isn't acknowledging. This is almost always **client-side DPI fingerprinting the Reality TLS pattern**, not a server bug. Server logs will be silent.

Mitigations to try, in order:
1. **Change the Reality SNI** to a target with a smaller cert chain — `gateway.icloud.com`, `www.cloudflare.com`, `discord.com`. Edit the inbound in 3x-ui (both `realitySettings.serverNames` and `realitySettings.settings.serverName`), restart x-ui.
2. **Move the inbound off port 443** to something less scrutinised (`2087`, `2096`, `8443`). DPI policy is sometimes port-specific.
3. **Switch the IP off the ISP's blacklist** — once an IP is fingerprinted by an aggressive DPI, even a fresh protocol from the same IP often fails. Rotate the VPS IP if possible.
4. **Front behind Cloudflare** — switch to VLESS+WS+TLS, point a domain at Cloudflare proxy mode, configure CF to origin to your VPS. The DPI sees only Cloudflare IPs.
5. **Try a different protocol** (Hysteria2 over QUIC, shadowsocks-2022). Reality detection has improved markedly in Iranian DPI through 2024–2025; a network that detects it may not yet detect QUIC-based tunnels.

Reality on its own is no longer guaranteed to evade Iranian DPI — design for fallbacks.

### VLESS+WebSocket behind Cloudflare (the post-Reality answer)

When direct VLESS or Reality stops getting through, Cloudflare fronting is the most reliable next step. Idea: client connects to a Cloudflare IP (CF whitelisted by most ISPs because of how much legit traffic it serves), CF terminates user TLS, then proxies WebSocket-wrapped VLESS to your origin VPS over CF's backbone. ISP sees only CF IPs and CF SNIs.

**One-time setup:**

1. **Move your domain to Cloudflare** — free plan is enough. Change registrar nameservers to the two CF ones. DNS propagates in minutes.
2. **DNS records in CF:**
   - Apex / existing subdomain used by direct-access services (e.g., TrustTunnel): **DNS-only (gray cloud)** to keep direct access working.
   - New subdomain for the fronted tunnel (e.g., `cdn.<your-domain>`): **Proxied (orange cloud)** A-record to your VPS IP. Keep it **1-level** (`cdn.example.com`, not `cdn.sub.example.com`) so Universal SSL covers it on Free tier.
3. **SSL/TLS → Overview** → set encryption mode **Full (strict)**.
4. **SSL/TLS → Origin Server** → **Create Certificate** (15-year cert, covers `*.<domain>` and `<domain>` by default). Save cert and private key — they go on the VPS.
5. **On the VPS**, install the origin cert (e.g., `/etc/x-ui/cert/cf-origin.{crt,key}`, 0600/0644 perms).
6. **In 3x-ui**, add a VLESS+WS+TLS inbound:
   - Port: any CF-supported HTTPS port for Free tier — 443, 2053, 2083, 2087, 2096, 8443
   - Transport: `ws`, path: random (e.g., `/wsm-<8-hex>`) for stealth
   - Host header: your CF-proxied subdomain
   - TLS: enabled, server name = your CF-proxied subdomain, cert = the origin cert
   - Flow: empty (xtls-rprx-vision is TCP-only, doesn't work with WS)

**Client URI** (v2rayNG / V2Box / Hiddify Next):
```
vless://<uuid>@<cdn-subdomain>:443?type=ws&path=%2F<ws-path>&host=<cdn-subdomain>&security=tls&sni=<cdn-subdomain>&fp=chrome&encryption=none#<remark>
```

**Verification from a third machine** (rules out cert/path bugs before bothering the user):
```bash
curl -sI https://<cdn-subdomain>/                                   # expect 404 or some response from origin
curl -sI -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  https://<cdn-subdomain>/<ws-path>                                 # expect 101 Switching Protocols
```
A `101` confirms the full chain (DNS → CF → origin TLS → WS upgrade) works.

**Common CF-fronting gotchas:**
- Universal SSL only covers `<domain>` and `*.<domain>` (one level). `cdn.sub.example.com` triggers a cert mismatch and 15-second silent timeouts. Use one-level subdomains.
- Free plan doesn't allow custom ports outside the supported list. Stick to 443/2053/2083/2087/2096/8443 for HTTPS, or 80/8080/8880/2052/2082/2086/2095 for plain HTTP.
- `xtls-rprx-vision` flow does NOT work over WebSocket — leave flow empty for VLESS+WS.

#### When even CF fronting fails (ISP does aggressive SNI whitelisting)

Some restrictive ISPs whitelist a small list of well-known SNIs (`www.cloudflare.com`, `www.google.com`, etc.) and drop everything else, even other CF subdomains. Telltale signs:
- `https://www.cloudflare.com` works in the user's browser, but `https://<your-cdn-subdomain>` times out after 15s
- `https://1.1.1.1` (bare-IP TLS, no SNI) also times out

Fixes, in order of likelihood:
1. **Encrypted Client Hello (ECH)** — CF publishes ECH config in DNS HTTPS records by default. Clients that support ECH (Hiddify Next recent versions) hide the SNI from the ISP. Requires the client to use DoH to fetch the HTTPS record, which means the ISP must also allow at least one DoH endpoint. If ISP blocks `cloudflare-dns.com` too, try `https://doh.opendns.com/dns-query`, `https://dns.adguard-dns.com/dns-query`, or `https://dns.nextdns.io/dns-query`.
2. **Different network** — mobile carriers in censored countries often have looser SNI filtering than landline ISPs. Users on mobile data may not need any of this.
3. **CDN diversification** — set up a parallel inbound fronted by Fastly or a different CDN. Some ISP whitelists are CF-specific; a different CDN's SNI pattern may pass.

#### Symptom: 3x-ui v3.x inserts inbound but xray config shows `"clients": null`
v3.x stores clients in the separate `clients` table, not embedded in `inbounds.settings`. After inserting an inbound via SQL, also insert the client and link via `client_inbounds`:
```sql
INSERT INTO clients (email, sub_id, uuid, flow, security, enable, created_at, updated_at)
VALUES (...);
INSERT INTO client_inbounds (client_id, inbound_id, flow_override, created_at)
VALUES ((SELECT id FROM clients WHERE uuid='...'), <inbound_id>, '', strftime('%s','now'));
```
Then `systemctl restart x-ui` to regenerate `/usr/local/x-ui/bin/config.json`.

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
# Check iptables rules exist AND are persistent
iptables -t raw -L -n | grep 9999
iptables -t mangle -L -n | grep 9999
dpkg -l iptables-persistent | grep ^ii   # MUST be installed or rules vanish on reboot

# Check pcap is working
tcpdump -i <interface> port 9999 -c 5

# Logs
journalctl -u paqet -f
```

#### Critical: scope the NOTRACK rules to the server's own IP
The setup-guide recipe uses `-p tcp --dport 9999 -j NOTRACK` with no destination. On a server that **also acts as a NAT gateway** (Tailscale exit node, WireGuard concentrator, etc.), this rule matches **forwarded** traffic with dport 9999 too — and NOTRACK breaks MASQUERADE because the reverse-NAT has no state to match against. The same applies to any port you may add (e.g., 443 if you also run Reality/web on it).

Use the scoped form on multi-role servers:
```bash
iptables -t raw    -A PREROUTING -d <SERVER_IP>/32 -p tcp --dport 9999 -j NOTRACK
iptables -t raw    -A OUTPUT     -s <SERVER_IP>/32 -p tcp --sport 9999 -j NOTRACK
iptables -t mangle -A OUTPUT     -s <SERVER_IP>/32 -p tcp --sport 9999 --tcp-flags RST RST -j DROP
```

Symptom of the broken-broad rule: HTTPS through the Tailscale/WG exit times out, but ICMP/SSH still work. Tcpdump on `ens3` shows outbound SYNs from the exit but no replies make it back to the client.

#### Symptom: client says "tunnel works briefly then dies with closed pipe"
Almost always the NOTRACK rule was removed (often by a reboot without `iptables-persistent`). The kernel then sees the raw KCP "TCP" packets as unsolicited and sends RST to the client after the first ACK, killing the smux session. Re-add the rules and save with `netfilter-persistent save`.

#### Symptom: small HTTP requests succeed but HTTPS / large transfers fail
If iptables rules ARE in place and `tcpdump` on the server shows the client's packets arriving but only the small KCP control frames flow (no large data segments), the client-side ISP is fingerprinting the KCP-over-fake-TCP pattern. Paqet alone cannot evade this; switch the user to VLESS or Hysteria2 on the same VPS.

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
