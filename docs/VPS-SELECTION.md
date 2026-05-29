# VPS Selection Guide

> **Last updated:** 2026-02-24
> **Purchase approach:** Buy from Turkey, users are in Iran
> **Reference VPS** used while authoring this guide: 1 vCPU, 957 MB RAM, 20 GB disk — workable for a subset of protocols but tight for the full multivpn stack.

## Minimum Specs

| Resource   | Minimum        | Recommended      | Notes                                      |
|------------|----------------|------------------|--------------------------------------------|
| CPU        | 2 vCPU         | 4 vCPU           | 1 vCPU workable (protocols are I/O-bound)  |
| RAM        | 2 GB           | 4 GB             | Critical bottleneck for 5 concurrent protocols |
| Storage    | 40 GB SSD      | 80 GB NVMe       | 3x-ui panel + logs + OS need space         |
| Bandwidth  | 2 TB/mo        | 4 TB/mo          | ~20 devices across 5 protocols             |
| OS         | Ubuntu 24.04   | Ubuntu 24.04     |                                            |
| Network    | 1 Gbps         | 1 Gbps           |                                            |

### Estimated RAM Usage Per Protocol

| Protocol     | RAM Usage   | CPU Impact |
|--------------|-------------|------------|
| paqet        | ~250 MB     | ~2% (I/O-bound) |
| 3x-ui/VLESS  | ~100-200 MB | Low        |
| TrustTunnel  | ~50-100 MB  | Low        |
| SSH tunneling| ~10-30 MB   | Negligible |
| Tailscale    | ~50 MB      | Low        |
| **OS + system** | ~400-600 MB | —       |
| **Total**    | **~900-1300 MB** | —     |

---

## Provider Selection Criteria

1. **Iran accessibility** — VPS IP range must NOT be blocked by Iran's national firewall (tested from Iran IP)
2. **No Iran sanctions block** — Provider must not block Iran IPs (purchase from Turkey mitigates this)
3. **VPN/Proxy tolerance** — Provider must allow running VPN and proxy services
4. **EU location** — Germany (Frankfurt) or Netherlands preferred for lowest latency to Iran
5. **Small/medium provider** — Less likely to be in Iran's filtering databases than major providers
6. **Monthly billing** — For trial period before committing to long-term
7. **Crypto payment** — Preferred for privacy
8. **DDoS protection** — Basic protection included

---

## Iran Accessibility Test Results (2026-02-24)

Tested from Iranian IP address to check if provider websites/panels are accessible.

| Provider      | Website         | Panel/Control     | Status         |
|---------------|-----------------|-------------------|----------------|
| Hostkey       | hostkey.com     | hostkey.com       | **Accessible** |
| Hosteons      | hosteons.com    | my.hosteons.com   | **Accessible** |
| Clouvider     | clouvider.com   | console.clouvider.co.uk | **Accessible** |
| BuyVM         | buyvm.net       | buyvm.net         | **Accessible** |
| Hetzner       | hetzner.com     | hetzner.com       | **Accessible** |
| Fotbo         | fotbo.com       | fotbo.com         | **Accessible** |
| IONOS         | ionos.com       | login.ionos.com   | **Accessible** |
| inet.ws       | inet.ws         | cloud.inet.ws     | **Accessible** |
| **Hostinger** | hostinger.com   | hpanel.hostinger.com | **BLOCKED**  |
| **eVPS.net**  | evps.net        | —                 | **BLOCKED**    |

> **Warning:** Website accessible does NOT guarantee VPS IPs are accessible. Websites use CDN (Cloudflare), but VPS servers sit on different IP ranges. The only real test is deploying a VPS and trying SSH from Iran.

---

## Comprehensive Provider Comparison

### Verified Pricing (as of 2026-02-24)

#### Budget EU Providers (Best for Iran)

| Provider | Plan | Cores | RAM | Storage | BW | Port | Price/mo | Location | Iran Test |
|----------|------|-------|-----|---------|-----|------|----------|----------|-----------|
| **Hostkey** | VM.v2-nano | 2 @ 2.9GHz | 4 GB | 60 GB NVMe | 3 TB | 1 Gbps | **EUR 4.37** | Netherlands | Site OK |
| **Hostkey** | VM.v3-pico | 1 @ 3.2GHz | 2 GB | 40 GB NVMe | 3 TB | 1 Gbps | EUR 4.61 | Netherlands | Site OK |
| **Hostkey** | VM.v3-nano | 2 @ 3.2GHz | 4 GB | 60 GB NVMe | 3 TB | 1 Gbps | EUR 4.96 | Netherlands | Site OK |
| **Hostkey** | VM.v2-mini | 4 @ 2.9GHz | 8 GB | 120 GB NVMe | 3 TB | 1 Gbps | **EUR 5.30** | Netherlands | Site OK |
| **Hosteons** | EU VPS 3 | 2 | 2 GB | 25 GB NVMe | 3 TB | 1 Gbps | **$5.00** | Frankfurt/Paris | Site OK |
| **Hosteons** | EU VPS 4 | 2 | 2.5 GB | 30 GB NVMe | 4 TB | 1 Gbps | $6.00 | Frankfurt/Paris | Site OK |
| **Hosteons** | EU VPS 5 | 3 | 3 GB | 40 GB NVMe | 5 TB | 1 Gbps | $7.00 | Frankfurt/Paris | Site OK |
| **Clouvider** | VPS.2 | 1 | 2 GB | 50 GB NVMe | 5 TB | 10 Gbps | **GBP 3.50** | Frankfurt/Amsterdam | Site OK |
| **Clouvider** | VPS.4 | 2 | 4 GB | 80 GB NVMe | 5 TB | 10 Gbps | **GBP 5.00** | Frankfurt/Amsterdam | Site OK |
| **Fotbo** | Cheap VPS | ? | ? | ? NVMe | ? | 1 Gbps | **EUR 4.80+** | NL/PL/DE | Site OK |

#### US/LU Providers

| Provider | Plan | Cores | RAM | Storage | BW | Port | Price/mo | Location | Iran Test |
|----------|------|-------|-----|---------|-----|------|----------|----------|-----------|
| **BuyVM** | SLICE 1024 | 1 | 1 GB | 20 GB | Unmetered | 1 Gbps | $3.50 | Luxembourg | Site OK |
| **BuyVM** | SLICE 2048 | 1 | 2 GB | 40 GB | Unmetered | 1 Gbps | **$7.00** | Luxembourg | Site OK |
| **Hosteons** | US VPS 3 | 2 | 2 GB | 25 GB | 3 TB | 1 Gbps | $5.00 | US (6 cities) | Site OK |
| **Hosteons** | US VPS 5 | 3 | 3 GB | 40 GB | 5 TB | 1 Gbps | $7.00 | US (6 cities) | Site OK |

#### Major Providers (Higher Iran filtering risk)

| Provider | Plan | Cores | RAM | Storage | BW | Port | Price/mo | Location | Iran Test |
|----------|------|-------|-----|---------|-----|------|----------|----------|-----------|
| **Hetzner** | CX23 | 2 | 4 GB | 40 GB | 20 TB | — | **EUR 3.49** | Germany/Finland | Site OK |
| **Hetzner** | CX32 | 4 | 8 GB | 80 GB | 20 TB | — | EUR 6.80 | Germany/Finland | Site OK |
| **IONOS** | VPS S | 2 | 2 GB | 80 GB NVMe | Unlimited | 1 Gbps | $3/mo* | US/DE/ES/UK | Site OK |
| **IONOS** | VPS M | 2 | 4 GB | 120 GB NVMe | Unlimited | 1 Gbps | $4/mo* | US/DE/ES/UK | Site OK |

> *IONOS prices are introductory for 12 months on a 3-year contract. Regular: $5/mo (S), $8/mo (M).

#### Eliminated Providers

| Provider | Plan | Specs | Price | Reason Eliminated |
|----------|------|-------|-------|-------------------|
| ~~eVPS.net~~ | Entry | 1c/3GB/40GB/5TB | EUR 3/mo | **Blocked from Iran** |
| ~~Hostinger~~ | KVM 1 | 1c/4GB/50GB/4TB | TRY 220.99/mo (~$6) | **Blocked from Iran** |
| ~~inet.ws~~ | 2GB | 1c/2GB/30GB | $3/mo | **5 Mbps bandwidth cap** — unusable for VPN |
| ~~Kamatera~~ | $4 plan | 1c/1GB/20GB | $4/mo | Insufficient specs (1 GB RAM) |
| ~~ChicagoVPS~~ | Cloud | 1c/1GB/20GB | ~$1.66/mo | Insufficient specs (1 GB RAM) |
| ~~HudsonValleyHost~~ | Self-managed | — | ~$3.95/mo | OpenVZ only (not KVM) |
| ~~PloxHost~~ | NVMe | — | ~$4/mo | Gaming-focused, specs unclear |
| ~~Virtono~~ | KVM 2G | 1c/2GB/50GB/2TB | EUR 9.95/mo | Too expensive |
| ~~Aquatis~~ | HR-KVM 8GB | 2c/8GB/40GB/1TB | $4/mo | US only + 1 TB BW + 337% price hike controversy |

---

## Long-Term Pricing

| Provider | Monthly | Annual/Long-term | Savings | Notes |
|----------|---------|------------------|---------|-------|
| **Hostkey VM.v2-nano** | EUR 4.37 | Monthly only (30% off vs hourly) | — | No annual |
| **Hosteons EU** | $5-7 | Yearly plans available; WELCOME20 coupon (20% off) | ~20% | |
| **Clouvider VPS.2** | GBP 3.50 | GBP 36.96/yr (GBP 3.15/mo) | 10% | |
| **Clouvider VPS.4** | GBP 5.00 | GBP 52.80/yr (GBP 4.40/mo) | 12% | |
| **BuyVM 2GB** | $7.00 | No annual discount | — | Already cheap |
| **Hetzner CX23** | EUR 3.49 | Hourly billing, no lock-in | — | Pay by the hour |

---

## Budget Tier Recommendations

### Tier 1: Up to $4/month

| Rank | Provider | Specs | Price | Iran Risk | Strategy |
|------|----------|-------|-------|-----------|----------|
| 1 | **Hetzner CX23** | 2 vCPU, 4 GB, 40 GB, 20 TB | EUR 3.49 | HIGH (IPs often filtered + sanction-buster contamination) | Hourly billing = free to test |
| 2 | **Hosteons Intel Frankfurt** | 1 core, 2 GB, 25 GB NVMe, 2 TB | $2.99 | LOW (small provider) | Monthly, yearly available |
| 3 | **Hosteons Ryzen Frankfurt** | 1 core, 2 GB, 25 GB NVMe, 2 TB | $3.99 | LOW | Monthly, yearly available |

> **Note:** At this tier, no plan fully meets all minimums (2 vCPU + 40 GB). Hetzner has best specs but highest Iran risk.

### Tier 2: Up to $6/month (Sweet Spot)

| Rank | Provider | Specs | Price | Iran Risk | Strategy |
|------|----------|-------|-------|-----------|----------|
| 1 | **Hostkey VM.v2-nano** | **2c, 4 GB, 60 GB NVMe**, 3 TB | EUR 4.37 (~$4.70) | LOW-MED (NL, est. 2007) | First choice to test |
| 2 | **Hostkey VM.v3-nano** | **2c, 4 GB, 60 GB NVMe**, 3 TB | EUR 4.96 (~$5.33) | LOW-MED | DDR5, faster CPU |
| 3 | **Clouvider VPS.4 Frankfurt** | **2c, 4 GB, 80 GB NVMe**, 5 TB, 10Gbps | GBP 5 (~$6.40) | LOW-MED | Annual: GBP 4.40/mo |

> **Best value:** Hostkey VM.v2-nano at EUR 4.37 — meets all minimums (2 cores, 4 GB, 60 GB), NL datacenter, established since 2007.

### Tier 3: Up to $8/month

| Rank | Provider | Specs | Price | Iran Risk | Strategy |
|------|----------|-------|-------|-----------|----------|
| 1 | **Hostkey VM.v2-mini** | **4c, 8 GB, 120 GB NVMe**, 3 TB | EUR 5.30 (~$5.70) | LOW-MED | Best specs/price ratio of ALL tiers |
| 2 | **BuyVM Luxembourg** | 1c, 2 GB, 40 GB, UNMETERED | $7.00 | LOW (proven for Iran) | Most battle-tested |
| 3 | **Hosteons EU VPS 5 Frankfurt** | 3c, 3 GB, 40 GB NVMe, 5 TB | $7.00 | LOW | VPN-friendly, yearly available |

> **Best value:** Hostkey VM.v2-mini at EUR 5.30 — 4 cores + 8 GB + 120 GB is absolutely overkill for multivpn. BuyVM Luxembourg is safest for proven Iran access.

---

## Provider Details

### Hostkey (hostkey.com) — Netherlands
- **HQ:** Netherlands, est. 2007
- **Jurisdiction:** Netherlands (EU)
- **DCs:** Netherlands (primary), US, Iceland
- **VPN Policy:** Allowed (no explicit restriction found)
- **Payment:** Card, PayPal, crypto
- **Iran website test:** Accessible
- **Strengths:** Excellent specs/price, established provider, NL datacenter
- **Weaknesses:** 3 TB bandwidth on cheapest plans

### Hosteons (hosteons.com) — Singapore
- **HQ:** Singapore (operations), India
- **Jurisdiction:** Singapore (no Iran sanctions)
- **DCs:** US (6 cities), Frankfurt (DE), Paris (FR)
- **VPN Policy:** Personal VPN explicitly allowed (blog promotes VPN setup)
- **Payment:** Card, PayPal, crypto (no KYC)
- **Iran website test:** Accessible
- **Strengths:** VPN-friendly, Frankfurt location, Singapore jurisdiction, accepts crypto
- **Weaknesses:** EU plans have smaller storage (25-40 GB)
- **Coupons:** WELCOME20 (20% off)

### Clouvider (clouvider.com) — UK
- **HQ:** United Kingdom
- **Jurisdiction:** UK
- **DCs:** 11 locations (Frankfurt, Amsterdam, London, Manchester, 7 US cities)
- **VPN Policy:** No explicit restriction found
- **Payment:** Card, PayPal, crypto, AliPay
- **Iran website test:** Accessible
- **Strengths:** 10 Gbps port, 100% uptime SLA, Frankfurt/Amsterdam locations
- **Weaknesses:** GBP pricing slightly over budget at monthly rates
- **Annual discount:** ~10-12% off

### BuyVM / FranTech (buyvm.net) — Canada
- **HQ:** Canada
- **Jurisdiction:** Canada
- **DCs:** Luxembourg, Las Vegas, New York, Miami
- **VPN Policy:** VPN-friendly (well-known for this use case)
- **Payment:** Card, crypto (via Stallion)
- **Iran website test:** Accessible
- **Strengths:** Unmetered bandwidth, Luxembourg historically accessible from Iran, proven track record
- **Weaknesses:** Often out of stock, 1 core only on cheap plans
- **Iran track record:** Luxembourg IPs have been among the most reliable from Iran

### Hetzner (hetzner.com) — Germany
- **HQ:** Germany
- **Jurisdiction:** Germany (EU)
- **DCs:** Falkenstein, Nuremberg (DE), Helsinki (FI), Ashburn (US)
- **VPN Policy:** Allowed but may flag abuse reports; strict TOS
- **Payment:** Card, PayPal, bank transfer
- **Iran website test:** Accessible
- **Strengths:** Best specs/price ratio, hourly billing (zero-risk testing), huge bandwidth
- **Weaknesses:**
  - IPs frequently targeted by Iran's firewall
  - ~10% of Hetzner German IPs contaminated by Iranian sanction-busting activity
  - Third parties (Google, AWS) also block some Hetzner IPs due to this
- **References:** [Cloud66 blog on Hetzner sanction-busting](https://blog.cloud66.com/hetzner-connectivity-issues-due-to-sanction-busting-activities)

### IONOS (ionos.com) — Germany/US
- **HQ:** Germany (1&1 IONOS)
- **Jurisdiction:** Germany + US entity
- **DCs:** US, Germany, Spain, UK
- **VPN Policy:** Standard corporate TOS, may flag VPN abuse
- **Payment:** Card
- **Iran website test:** Accessible
- **Strengths:** Excellent specs (2 vCores, unlimited traffic), NVMe storage
- **Weaknesses:** Requires 3-year contract for advertised pricing; intro pricing increases 60-100% after 12 months
- **Monthly real price:** VPS S = $5/mo regular, VPS M = $8/mo regular

### Fotbo (fotbo.com) — Netherlands/Poland/Germany
- **HQ:** European (NL-based)
- **DCs:** Netherlands (NorthC), Poland (Beyond), Germany (Telehouse Frankfurt)
- **VPN Policy:** VPN-friendly (offers dedicated VPN VPS product)
- **Payment:** Card, crypto
- **Iran website test:** Accessible
- **VPN product:** EUR 4.80/mo — 1 vCore, 2.5 GB RAM, 15 GB NVMe, pre-configured with VLESS/VMess/ShadowSocks/Socks5/WireGuard/OpenVPN
- **VPN product verdict:** NOT suitable for multivpn (15 GB storage too small, 1 vCore). Good for simple personal VPN but not for running 5 custom protocols.
- **Regular VPS:** Starting EUR 4.80/mo — specs unclear, check website for current plans

---

## Iran Filtering Technical Background

### How Iran Filters Internet Traffic
1. **DPI (Deep Packet Inspection):** Detects VPN protocols (VLESS, VMess, Shadowsocks, Hysteria) and blocks them. paqet bypasses this via raw packet injection.
2. **DNS Injection:** Forged DNS responses pointing to 10.10.34.* addresses.
3. **IP Range Blocking:** Drops all traffic to/from certain IP ranges. Even paqet cannot bypass this.
4. **SNI Inspection:** Terminates HTTPS connections by inspecting SNI and sending RST packets.
5. **UDP Dropping:** Notably impacts QUIC protocol.

### Key Insight
Since paqet bypasses DPI, the **main concern is IP-level blocking**. If Iran blocks the entire IP range of a hosting provider, no protocol (including paqet) can reach the server.

### Why Small Providers Are Safer
- Iran's filtering databases focus on major providers (AWS, Google Cloud, Hetzner, etc.)
- Small/niche providers have IP ranges that are less likely to be cataloged
- European IPs generally less targeted than US IPs (but Hetzner is an exception)

### Hetzner-Specific Risk
- ~10% of Hetzner's German IPs have been used by Iranian sanction-busting entities
- Iran's government may specifically target Hetzner ranges to block these
- Third parties (Google, AWS, Azure) also block contaminated Hetzner IPs
- Result: double risk of VPS IP being inaccessible

### June 2025 Iran Internet Shutdown
- Following military escalations, Iran activated national firewall aggressively
- All major VPN protocols (VLESS, VMess, Shadowsocks, Hysteria) became non-functional
- Only SSH remained as a high-speed, direct-working protocol on major ISPs
- Current status: filtering remains aggressive but not at shutdown levels

---

## Location Recommendations

| Priority | Location                | Latency to Iran | Why                                              |
|----------|-------------------------|-----------------|--------------------------------------------------|
| 1st      | Netherlands (Amsterdam) | ~60-80ms        | Major IX hub, good connectivity, less filtered    |
| 2nd      | Germany (Frankfurt)     | ~50-70ms        | Closest EU hub, but Hetzner IPs are risky         |
| 3rd      | Luxembourg              | ~70-90ms        | BuyVM location, proven Iran accessibility          |
| 4th      | France (Paris)          | ~70-90ms        | Good alternative to Germany                        |
| 5th      | US East (New York)      | ~150ms          | Acceptable latency, many cheap providers           |
| Avoid    | US West Coast           | ~200ms+         | High latency to Iran                               |
| Avoid    | Asia                    | Inconsistent    | Routing through Iran's eastern links is unreliable |

---

## Recommended Testing Strategy

### Step 1: Zero-Risk Test with Hetzner (EUR 0.01)
1. Create Hetzner Cloud account (free)
2. Deploy CX23 in Falkenstein, Germany
3. From Iran: `ssh root@<ip>` and `ping <ip>`
4. If works: keep it (EUR 3.49/mo, best specs)
5. If blocked: delete server (costs only pennies for a few minutes)

### Step 2: Test Hostkey (EUR 4.37)
1. Deploy VM.v2-nano in Netherlands
2. Test SSH from Iran
3. If works: excellent choice (2 cores, 4 GB, 60 GB)
4. If blocked: request IP change or cancel

### Step 3: Fallback to BuyVM Luxembourg ($7)
1. Deploy SLICE 2048 in Luxembourg
2. Most historically reliable from Iran
3. If even this fails: Iran may be in a major filtering escalation period

### General Pre-Purchase Checklist
1. Test provider website accessibility from Iran IP
2. Confirm VPN/proxy usage is allowed (check TOS)
3. Verify stock availability in desired location
4. Choose monthly billing for first month (trial)
5. After purchase: immediately test SSH from Iran before configuring
6. If SSH blocked: request IP change (usually free for first request)
7. If still blocked: cancel and try next provider

### Post-Purchase IP Check
```bash
# From inside Iran, test connectivity
ping <server-ip>
ssh root@<server-ip>
curl -v https://<server-ip>:443
nmap -Pn -p 22,443,8443 <server-ip>

# If blocked, contact provider for IP change (usually free)
```

---

## Quick Reference: Best Picks

| Budget    | Provider                 | Specs                          | Price          | Action                    |
|-----------|--------------------------|--------------------------------|----------------|---------------------------|
| Cheapest  | Hetzner CX23             | 2c/4GB/40GB/20TB               | EUR 3.49/mo    | Test first (hourly billing) |
| Best value| **Hostkey VM.v2-nano**   | **2c/4GB/60GB/3TB**            | **EUR 4.37/mo**| **Top recommendation**    |
| Overkill  | Hostkey VM.v2-mini       | 4c/8GB/120GB/3TB               | EUR 5.30/mo    | Best specs under $6       |
| Safest    | BuyVM Luxembourg         | 1c/2GB/40GB/unmetered          | $7.00/mo       | Proven Iran track record  |
| VPN-ready | Clouvider VPS.4 Frankfurt| 2c/4GB/80GB/5TB/10Gbps         | GBP 5.00/mo    | Annual: GBP 4.40/mo       |
