# 3x-ui Post-Installation Guide

## 1. Access the Panel

Open `https://<server-ip>:2053` in your browser.

Log in with the credentials you set during installation.

## 2. Create VLESS + Reality Inbound

Go to **Inbounds** > **Add Inbound** and configure:

| Setting | Value |
|---------|-------|
| Remark | `vless-reality` |
| Protocol | `vless` |
| Listen IP | (leave empty) |
| Port | `443` |
| Total Traffic | `0` (unlimited) or set a limit |

Under **Client** section (auto-created first user):
| Setting | Value |
|---------|-------|
| Email | `user1@vpn` (identifier, not real email) |
| Flow | `xtls-rprx-vision` |
| Limit IP | `3` (max concurrent devices) |
| Total Traffic (GB) | `100` or `0` for unlimited |
| Expiry Time | Set as needed |

Under **Transport** settings:
| Setting | Value |
|---------|-------|
| Transmission | `tcp` |

Under **Security** settings:
| Setting | Value |
|---------|-------|
| Security | `reality` |
| uTLS | `chrome` |
| Dest (SNI) | `www.google.com:443` |
| Server Names | `www.google.com` |
| Get new cert | Click to generate Reality keys |

Click **Create** to save.

## 3. Create Users

For each user (up to 10):

1. Click on the inbound row to expand it
2. Click **+** (Add Client)
3. Fill in:
   - **Email**: descriptive name (e.g., `ali-phone`, `sara-laptop`)
   - **Flow**: `xtls-rprx-vision`
   - **Limit IP**: `3`
   - **Total Traffic**: as needed
   - **Expiry**: as needed
4. Click **Submit**

## 4. Export Connection Links

For each user:

1. Click the **QR code** icon next to their name
2. Options:
   - **Copy link** — share the VLESS:// URI directly
   - **QR Code** — screenshot and send to user
   - **Subscription link** — if subscription is enabled (Settings > Subscription)

### Enable Subscription (Recommended)

1. Go to **Panel Settings** > **Subscription**
2. Enable subscription
3. Set subscription port (e.g., `2096`)
4. Open the port in UFW: `ufw allow 2096/tcp`
5. Each user gets a subscription URL that auto-updates when you change server config

## 5. Recommended Panel Settings

### Panel Settings
- **Panel Port**: 2053 (already set)
- **Enable HTTPS for panel**: Yes (uses self-signed cert)
- **Session timeout**: 60 minutes
- **Traffic reset day**: 1 (resets monthly on the 1st)

### Xray Configuration
- Go to **Xray Settings** > **Basic**
- Ensure **Block BitTorrent** is checked (prevents abuse)
- Enable **Block Iran domestic domains** if available (prevents routing Iran-to-Iran through VPS)

## 6. Telegram Bot (Optional)

1. Create a bot via @BotFather on Telegram
2. Go to **Panel Settings** > **Telegram Bot**
3. Enter:
   - Bot token
   - Admin chat ID (get from @userinfobot)
4. Enable notifications for:
   - User traffic limit reached
   - User expiry
   - System load alerts

## 7. Reality SNI Selection

Good SNI choices (high-traffic sites that support TLS 1.3 + H2):

| SNI | Notes |
|-----|-------|
| `www.google.com` | Most reliable, widely used |
| `www.microsoft.com` | Good alternative |
| `www.apple.com` | Works well |
| `dl.google.com` | Download-like traffic pattern |
| `www.samsung.com` | Less common, may avoid detection |

**Test SNI from server:**
```bash
# Should return TLS handshake success
curl -I --resolve www.google.com:443:<server-ip> https://www.google.com
```

## 8. Troubleshooting

### Users can't connect
1. Check inbound is active (green indicator)
2. Verify port 443 is open: `ss -tlnp | grep 443`
3. Check Xray logs: `journalctl -u x-ui -f`
4. Verify Reality keys match between server and client config

### High CPU usage
1. Check connected users in panel dashboard
2. Look for users with abnormally high traffic (BitTorrent)
3. Enable BitTorrent blocking in Xray settings

### Panel not accessible
1. Check service status: `systemctl status x-ui`
2. Check port: `ss -tlnp | grep 2053`
3. Check UFW: `ufw status | grep 2053`
4. Restart: `systemctl restart x-ui`
