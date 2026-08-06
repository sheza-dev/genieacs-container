# Production Templates (HQ + Branch + Reverse Proxy)

This folder provides ready-to-use templates for:

- `mikrotik-pusat-final.rsc` (HQ WireGuard hub + firewall + NAT + port-forwarding)
- `mikrotik-cabang-cinde-final.rsc` (CINDE branch WireGuard spoke + firewall + NAT)
- `nginx.conf` (TLS reverse proxy for GenieACS UI and CWMP)
- `docker-compose.override.yml` (production override to put GenieACS behind Nginx)

## Topology assumptions

- HQ has static public IP on MikroTik WAN (ISP2).
- Branches are dynamic/CGNAT and initiate the tunnel to HQ.
- Ubuntu GenieACS host is `172.16.27.26`.
- Management laptop is `172.16.27.100`.

## Import order (safe)

1. Fill placeholders (`PASTE_*`, `X.X.X.X`, interface names).
2. Import HQ script.
3. Import branch script.
4. Verify tunnel (`/interface/wireguard/peers/print`).
5. Deploy Compose with override:

```bash
docker compose -f docker-compose.yml -f examples/production/docker-compose.override.yml up -d
```

## Required environment variables (`.env`)

```env
GENIEACS_UI_JWT_SECRET=replace-with-strong-random-secret
GENIEACS_MONGODB_CONNECTION_URL=mongodb://mongo/genieacs?authSource=admin
```

## No-conflict checklist

- WG transit subnet `10.250.50.0/30` is not used anywhere else.
- Branch LANs do not overlap with HQ (`172.16.27.0/24`, `10.100.27.0/24`, `10.10.30.0/24`, `10.30.10.0/24`).
- Internet-exposed ports are limited to `443/tcp`, `7547/tcp`, and `51820/udp`.
- Internal-only ports (`3000`, `7557`, `7567`, `27017`) are not public.
