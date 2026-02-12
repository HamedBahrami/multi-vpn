# Multi-Protocol VPN Server

Automated setup scripts for a multi-protocol VPN/proxy server designed to bypass internet censorship. Runs 5 protocols simultaneously so users have fallback options if one gets blocked.

## Protocols

| Protocol | Port | Anti-Censorship | UDP Support | User Management |
|----------|------|-----------------|-------------|-----------------|
| **VLESS Reality** | 443/tcp | Excellent — looks like normal HTTPS | Via Xray | 3x-ui web panel (per-user limits) |
| **TrustTunnel** | 8443/tcp+udp | Good — HTTP/2 + QUIC tunneling | Yes (QUIC) | credentials.toml |
| **Paqet** | 9999 | Excellent — raw packet injection bypasses DPI | Yes | Shared key (no per-user) |
| **SSH Tunnel** | 22/tcp | Moderate — SSH is fingerprintable | No | Linux users + sshd |
| **Tailscale** | 41641/udp | Moderate — uses DERP relays on port 443 | Yes | Tailscale admin console |

## Quick Start

### 1. Get a VPS

See [`docs/VPS-SELECTION.md`](docs/VPS-SELECTION.md) for provider recommendations and specs.

**Minimum:** 2 CPU, 2 GB RAM, 2 TB bandwidth, Ubuntu 24.04 LTS

### 2. Deploy Scripts

```bash
# Clone to VPS
git clone https://github.com/HamedBahrami/multi-vpn.git
cd multi-vpn

# Run initial setup (replace ens3 with your server interface)
sudo bash scripts/00-initial-setup.sh ens3
```

### 3. Install Protocols

Run each setup script in order:

```bash
# SSH tunneling
sudo bash scripts/01-ssh-tunneling/setup.sh

# 3x-ui panel (VLESS Reality)
sudo bash scripts/02-3xui/setup.sh

# TrustTunnel
sudo bash scripts/03-trusttunnel/setup.sh

# Paqet
sudo bash scripts/04-paqet/setup.sh ens3

# Tailscale
sudo bash scripts/05-tailscale/setup.sh

# Monitoring
sudo bash scripts/06-monitoring/setup.sh
```

### 4. Add Users

```bash
# SSH tunnel user
sudo bash scripts/01-ssh-tunneling/add-user.sh <username> <password>

# TrustTunnel user
sudo bash scripts/03-trusttunnel/add-user.sh <username> <password>

# VLESS users — create via 3x-ui web panel at https://<server-ip>:2053

# Paqet — share the KCP key with users (no per-user accounts)

# Tailscale — invite users to your tailnet at login.tailscale.com
```

## Project Structure

```
scripts/
├── 00-initial-setup.sh          # OS hardening, firewall, sysctl tuning
├── 01-ssh-tunneling/
│   ├── setup.sh                 # Configure sshd for tunnel-only users
│   ├── add-user.sh              # Create tunnel-only user
│   └── remove-user.sh           # Delete user
├── 02-3xui/
│   ├── setup.sh                 # Install 3x-ui panel
│   └── post-install.md          # VLESS Reality setup guide (web panel)
├── 03-trusttunnel/
│   ├── setup.sh                 # Install TrustTunnel server
│   ├── add-user.sh              # Add user to credentials
│   └── remove-user.sh           # Remove user from credentials
├── 04-paqet/
│   ├── setup.sh                 # Install paqet with auto-detection
│   └── server.yaml.template     # Config template
├── 05-tailscale/
│   └── setup.sh                 # Install + advertise exit node
└── 06-monitoring/
    ├── setup.sh                 # fail2ban, vnstat, cron logging
    └── check-usage.sh           # Per-protocol usage report
docs/
├── VPS-SELECTION.md             # VPS provider recommendations
├── USER-GUIDE.md                # Client setup for all protocols
└── ADMIN-GUIDE.md               # Server maintenance and troubleshooting
```

## Monitoring

```bash
# Quick usage report
check-usage

# Bandwidth stats
vnstat -d    # daily
vnstat -m    # monthly

# fail2ban status
fail2ban-client status sshd
```

## Capacity

Designed for **~10 users** (1-3 people, up to 3 devices each, ~20 concurrent devices peak).

- VLESS: 3 concurrent devices per user (configurable in 3x-ui)
- SSH: 3 sessions per user (sshd MaxSessions)
- TrustTunnel: no per-user limit (monitor and revoke if abused)
- Paqet: shared key, no per-user limits
- Tailscale: free tier supports 3 users, 100 devices

## Documentation

- **Users:** [`docs/USER-GUIDE.md`](docs/USER-GUIDE.md) — per-protocol client setup for Android, iOS, Windows, macOS, Linux
- **Admins:** [`docs/ADMIN-GUIDE.md`](docs/ADMIN-GUIDE.md) — user management, monitoring, credential rotation, troubleshooting
- **VPS selection:** [`docs/VPS-SELECTION.md`](docs/VPS-SELECTION.md) — provider comparison, specs, location advice

## Security Notes

- The initial setup script enables UFW firewall, fail2ban, and unattended security upgrades
- SSH tunnel users get no shell access (ForceCommand /bin/false)
- 3x-ui admin panel should be restricted to admin IP via UFW
- Paqet's shared key should be rotated if compromised
- No real credentials are stored in this repository — all secrets are generated at deploy time

## License

MIT
