FROM debian:bookworm-slim

ARG ARCH=amd64

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl jq && \
    rm -rf /var/lib/apt/lists/*

# Download latest TrustTunnel release
# If auto-download fails, manually place the binary at docker/trusttunnel/trusttunnel-server
# and uncomment the COPY line below instead.
RUN set -eux; \
    URL=$(curl -sL https://api.github.com/repos/nickolaev/trusttunnel/releases/latest \
      | jq -r ".assets[] | select(.name | contains(\"linux-${ARCH}\")) | .browser_download_url" \
      | head -1); \
    if [ -n "$URL" ] && [ "$URL" != "null" ]; then \
      curl -Lo /tmp/trusttunnel.tar.gz "$URL" && \
      tar -xzf /tmp/trusttunnel.tar.gz -C /usr/local/bin/ 2>/dev/null || \
      mv /tmp/trusttunnel.tar.gz /usr/local/bin/trusttunnel-server && \
      chmod +x /usr/local/bin/trusttunnel-server; \
      rm -f /tmp/trusttunnel.tar.gz; \
    else \
      echo "WARNING: Could not download TrustTunnel. Place binary manually." >&2; \
    fi

# Alternative: copy a pre-downloaded binary
# COPY trusttunnel-server /usr/local/bin/trusttunnel-server

RUN chmod +x /usr/local/bin/trusttunnel-server 2>/dev/null || true

EXPOSE 8443/tcp 8443/udp

ENTRYPOINT ["trusttunnel-server"]
CMD ["--config", "/etc/trusttunnel/config.toml"]
