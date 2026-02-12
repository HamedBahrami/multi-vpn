# VPS Selection Guide

## Minimum Specs

| Resource   | Minimum   | Recommended      |
|------------|-----------|------------------|
| CPU        | 2 vCPU    | 4 vCPU           |
| RAM        | 2 GB      | 4 GB             |
| Storage    | 40 GB SSD | 80 GB NVMe      |
| Bandwidth  | 2 TB/mo   | 4 TB/mo          |
| OS         | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| Network    | 1 Gbps    | 1 Gbps           |

For ~20 concurrent devices across 5 protocols, 2 GB RAM is workable but tight. 4 GB gives headroom for 3x-ui panel, TrustTunnel, and paqet running simultaneously.

## Provider Selection Criteria

1. **VPN/Proxy tolerance** — Provider must allow running VPN and proxy services. Avoid providers that explicitly ban VPN usage in TOS.
2. **Peering to Iran** — Low latency from Iran (ideally <100ms). EU (Germany/Netherlands) or US East Coast typically work well.
3. **Abuse response** — Provider should send notices before taking action, not instantly null-route.
4. **Payment** — Crypto payment preferred for privacy; PayPal/card also acceptable.
5. **IP reputation** — The assigned IP must not already be blacklisted by Iran DPI. Request IP change if blocked.
6. **DDoS protection** — Basic DDoS protection included.

## Recommended Providers

### Tier 1 (Best for this use case)

**BuyVM (FranTech)**
- Location: Luxembourg, Las Vegas, New York, Miami
- Pricing: $3.50/mo (1 GB), $7/mo (2 GB), $15/mo (4 GB)
- Pros: Unmetered bandwidth, VPN-friendly, cheap, stable
- Cons: Often out of stock, no crypto payment directly (use Stallion for crypto)
- Best pick: Luxembourg or New York location

**RackNerd**
- Location: Multiple US + EU locations
- Pricing: ~$20-30/yr for 2 GB during sales
- Pros: Very cheap on Black Friday deals, VPN-friendly
- Cons: Mixed support quality, oversold sometimes
- Best pick: New York or Chicago location

**VMISS**
- Location: US, Japan, Hong Kong, Singapore
- Pricing: ~$5-8/mo for 2 GB
- Pros: Good Asian peering, accepts crypto
- Cons: Smaller provider, limited track record
- Best pick: US West or Japan (if targeting lower latency to Iran)

### Tier 2 (Good alternatives)

**Hetzner**
- Location: Germany (Falkenstein, Nuremberg), Finland, US
- Pricing: ~$4-8/mo (2-4 GB)
- Pros: Excellent network, reliable, good EU peering to Iran
- Cons: Strict TOS — may terminate for "proxy services" if reported. Don't advertise as VPN service.
- Best pick: Falkenstein, Germany

**OVH / OVHcloud**
- Location: France, Germany, Canada, US, Singapore
- Pricing: ~$3.50-7/mo (VPS range)
- Pros: Large network, good peering, DDoS protection included
- Cons: Bureaucratic support, may require ID verification
- Best pick: Gravelines (France) or Frankfurt

### Tier 3 (Budget / Specialized)

**V.PS**
- Location: Amsterdam, Frankfurt, London, US
- Pricing: ~$5-10/mo
- Pros: Premium network (AS136620), accepts crypto
- Cons: More expensive per spec

**1984 Hosting**
- Location: Iceland
- Pricing: ~$5-10/mo
- Pros: Privacy-focused, free speech friendly
- Cons: Iceland routing may add latency

## Location Recommendations

| Priority | Location              | Why                                        |
|----------|-----------------------|--------------------------------------------|
| 1st      | Germany (Frankfurt)   | Closest EU hub to Iran, good submarine cable routes |
| 2nd      | Netherlands (Amsterdam) | Major IX hub, good connectivity            |
| 3rd      | US East (New York)    | Acceptable latency (~150ms), many cheap providers |
| 4th      | France (Paris)        | Good alternative to Germany                |
| Avoid    | US West Coast         | High latency to Iran (~200ms+)             |
| Avoid    | Asia (unless specific need) | Routing through Iran's eastern links is inconsistent |

## Pre-Purchase Checklist

1. Check if provider's IP range is blocked in Iran:
   - Use a friend inside Iran to `ping` or `curl` the provider's looking glass IP
   - Or check via online tools from Iranian vantage points
2. Confirm VPN/proxy usage is allowed (check TOS or ask support)
3. Verify the provider has stock in your desired location
4. Choose a location with <150ms latency to Tehran
5. After purchase, immediately test SSH access from Iran before configuring anything

## Post-Purchase: IP Check

After getting your VPS, verify the IP is not already blocked:

```bash
# From inside Iran, test connectivity
ping <server-ip>
curl -v https://<server-ip>:443
nmap -Pn -p 22,443,8443 <server-ip>

# If blocked, contact provider for IP change (usually free for first request)
```
