# Docker Setup Guide

Docker is an **optional alternative** for running 3x-ui and TrustTunnel. Other services (Paqet, SSH, Tailscale, monitoring) run natively — see the main setup scripts.

## Install Docker

Run on your VPS (Ubuntu 24.04):

```bash
# Install Docker Engine
curl -fsSL https://get.docker.com | sh

# Add your user to docker group (avoid sudo for docker commands)
usermod -aG docker $USER

# Install Docker Compose plugin
apt install -y docker-compose-plugin

# Verify
docker --version
docker compose version
```

## Quick Start

```bash
cd /root/multi-vpn/docker

# Start both services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f x-ui
docker compose logs -f trusttunnel
```

## Managing Services

```bash
# Stop
docker compose down

# Restart a single service
docker compose restart x-ui

# Update to latest images
docker compose pull
docker compose up -d

# View resource usage
docker stats
```

## 3x-ui (VLESS Reality)

After starting, access the panel at `https://<server-ip>:2053`.

Default credentials are set via environment variables in `docker-compose.yml`. Change them before first start.

Data persists in `./data/3xui/` volume. To back up:
```bash
docker compose stop x-ui
cp -r data/3xui data/3xui.bak
docker compose start x-ui
```

Follow [post-install.md](../scripts/02-3xui/post-install.md) for VLESS Reality inbound setup — the web panel workflow is identical whether running native or Docker.

## TrustTunnel

User credentials are in `./data/trusttunnel/credentials.toml`.

```bash
# Add user (edit file directly, then restart)
cat >> data/trusttunnel/credentials.toml << 'EOF'

[[client]]
username = "alice"
password = "secure-password"
EOF

docker compose restart trusttunnel

# Remove user (edit file, remove the [[client]] block, then restart)
```

## Volumes and Data

```
docker/data/
├── 3xui/           # 3x-ui database, certs, Xray config
│   └── db/         # x-ui.db (user data, inbound config)
└── trusttunnel/    # TrustTunnel config + credentials
    ├── config.toml
    └── credentials.toml
```

All data lives on the host in `docker/data/`. Containers are stateless and can be recreated at any time without data loss.

## Mixing Docker and Native

You can run 3x-ui and TrustTunnel in Docker while running other services natively. They don't conflict as long as ports aren't double-bound:

| Service | Docker | Native | Port |
|---------|--------|--------|------|
| 3x-ui | `docker compose up -d x-ui` | `scripts/02-3xui/setup.sh` | 443, 2053 |
| TrustTunnel | `docker compose up -d trusttunnel` | `scripts/03-trusttunnel/setup.sh` | 8443 |

Pick one method per service — don't run both simultaneously.

## Troubleshooting

### Container won't start
```bash
docker compose logs <service-name>
docker inspect <container-id>
```

### Port already in use
Another process (or the native install) is using the port. Check with:
```bash
ss -tlnp | grep -E ':(443|2053|8443) '
```
Stop the conflicting service before starting the Docker version.

### Permission denied on volumes
```bash
chown -R 1000:1000 data/
```

### Reset 3x-ui admin password
```bash
docker compose exec x-ui /app/x-ui setting -username admin -password newpassword
docker compose restart x-ui
```
