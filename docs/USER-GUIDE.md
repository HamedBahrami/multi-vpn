# User Guide — Multi-Protocol VPN Server

This server provides multiple VPN/proxy protocols. If one gets blocked, try another.

**Priority order** (try these first):
1. VLESS Reality — best anti-detection, looks like normal HTTPS
2. TrustTunnel — HTTP/2 + QUIC tunneling
3. Paqet — raw packet proxy, bypasses DPI
4. SSH Tunnel — simple, works on most networks
5. Tailscale — WireGuard-based, good for general use

---

## 1. VLESS Reality (Recommended)

VLESS with Reality disguises your traffic as a normal HTTPS connection to a legitimate website. It's currently the hardest protocol for censors to detect.

### Android — v2rayNG / Hiddify

1. Install **v2rayNG** from Google Play or GitHub releases
2. Tap **+** > **Import config from clipboard**
3. Paste the VLESS link your admin gave you (starts with `vless://...`)
4. Or scan the QR code from the admin
5. Tap the **play** button to connect

**Alternative:** Install **Hiddify** — import the subscription URL for auto-updates.

### iOS — Streisand / V2Box

1. Install **Streisand** or **V2Box** from App Store
2. Import the VLESS link or scan QR code
3. Connect

### Windows — v2rayN / Hiddify

1. Download **v2rayN** from GitHub
2. Right-click tray icon > **Import from clipboard**
3. Paste the VLESS link
4. Select the server and click **Start**

### macOS — V2Box / Hiddify

1. Install from App Store or GitHub
2. Import link or QR code
3. Connect

---

## 2. TrustTunnel

TrustTunnel disguises traffic as HTTP/2 and QUIC, which looks like normal web browsing.

### Android

1. Install **TrustTunnel** client or **AdGuard VPN** (if compatible)
2. Enter server details:
   - Server: `<server-ip>`
   - Port: `8443`
   - Username: (provided by admin)
   - Password: (provided by admin)
3. Connect

### Windows / macOS

1. Download TrustTunnel client from GitHub releases
2. Configure:
   ```
   Server: <server-ip>
   Port: 8443
   Username: <your-username>
   Password: <your-password>
   ```
3. Connect — creates a system-wide VPN

---

## 3. Paqet

Paqet uses raw packet injection to bypass DPI. It creates a SOCKS5 proxy on your device.

**Note:** Paqet requires a routing tool (like sing-box) to route all traffic through its SOCKS5 proxy.

### Windows

1. Get the paqet client binary and config from admin
2. Save `client.yaml` with your settings:
   ```yaml
   role: "client"
   listen:
     addr: ":1080"
   network:
     interface: "Ethernet"  # or your interface name
     ipv4:
       addr: "<your-local-ip>:0"
       router_mac: "<your-router-mac>"
   transport:
     kcp:
       key: "<kcp-key-from-admin>"
   ```
3. Run: `paqet.exe -c client.yaml`
4. SOCKS5 proxy available at `localhost:1080`

**Finding your interface/MAC:**
- Interface: `ipconfig` — look for your active connection name
- Router MAC: `arp -a` — find your gateway IP's MAC address

### Routing all traffic through paqet

Use **sing-box** to create a TUN interface that routes everything through paqet's SOCKS5:

1. Download sing-box from GitHub
2. Use this config template (adjust as needed):
   ```json
   {
     "dns": {
       "servers": [{"tag": "remote-dns", "address": "udp://1.1.1.1", "detour": "paqet"}],
       "final": "remote-dns"
     },
     "inbounds": [{"type": "tun", "address": ["172.19.0.1/30"], "auto_route": true, "strict_route": false, "sniff": true}],
     "outbounds": [
       {"type": "socks", "tag": "paqet", "server": "127.0.0.1", "server_port": 1080},
       {"type": "direct", "tag": "direct"}
     ],
     "route": {
       "rules": [
         {"action": "hijack-dns", "protocol": "dns"},
         {"process_name": ["paqet.exe"], "outbound": "direct"}
       ],
       "final": "paqet",
       "auto_detect_interface": true
     }
   }
   ```
   > **Note:** Use Cloudflare DNS (`1.1.1.1`) — Google DNS (`8.8.8.8`) can route to CDN edges that return 503 errors on sites like X.com.
3. Run sing-box, then all traffic goes through the VPS

---

## 4. SSH Tunnel

The simplest option. Creates a SOCKS5 proxy through an SSH connection.

**Limitation:** SSH does NOT support UDP. Some apps (Telegram voice calls, gaming, corporate VPNs) won't work through SSH.

### Windows — Bitvise SSH Client

1. Download and install **Bitvise SSH Client**
2. Configure:
   - Host: `<server-ip>`
   - Port: `22`
   - Username: (provided by admin)
   - Password: (provided by admin)
3. Go to **Services** tab > **SOCKS/HTTP Proxy Forwarding**
   - Enable, listen on `127.0.0.1:1080`
4. Click **Log In**
5. Configure browser/apps to use SOCKS5 proxy at `127.0.0.1:1080`

### Windows / macOS / Linux — Command line

```bash
ssh -D 1080 -N -p 22 <username>@<server-ip>
```

This creates SOCKS5 on `localhost:1080`. Configure your browser to use it.

### Android — Matsuri / HTTP Injector

1. Install **Matsuri** or **HTTP Injector**
2. Add SSH profile:
   - Host: `<server-ip>`
   - Port: 22
   - Username / Password: (from admin)
   - Enable SOCKS5 proxy
3. Connect

---

## 5. Tailscale

Tailscale is a WireGuard-based mesh VPN. Simple setup, good for general internet access.

### Any platform

1. Install **Tailscale** from tailscale.com/download
2. Open Tailscale and sign in
3. Join the tailnet using the invite link from admin
4. Go to Tailscale settings > **Exit Node**
5. Select the VPS server as your exit node
6. All traffic now routes through the VPS

**Note:** Tailscale may be blocked by some ISPs. If it doesn't connect, try VLESS or Paqet instead.

---

## Troubleshooting

### None of the protocols connect
- Your ISP may be blocking the VPS IP entirely
- Ask admin to check if the server IP is blocked
- Try from a different network (mobile data vs WiFi)

### VLESS connects but very slow
- Try changing the SNI in your config (ask admin)
- ISP may be throttling — try at a different time of day
- Switch to Paqet which is harder to throttle

### SSH tunnel drops frequently
- Add keepalive: `ssh -o ServerAliveInterval=60 -D 1080 -N user@server`
- Or use Bitvise which has built-in keepalive

### Paqet won't start on Windows
- Run as Administrator
- Make sure Npcap is installed (not WinPcap)
- Check interface name matches exactly

### Tailscale won't connect
- Make sure you're on the same tailnet as the server
- Check that exit node is approved by admin
- Try disconnecting and reconnecting
