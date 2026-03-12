# WHALE MACHINE KNOWLEDGE BASE

## OVERVIEW

`whale/` is the highest-complexity host in the repo: server role, many local service files, reusable `profiles/server/*`, and all imported `apps/*`.

## WHERE TO LOOK

| Need | File |
|------|------|
| Host topology, imports, bridges, routing | `default.nix` |
| Mail NixOS container | `mail.nix` |
| CoreDNS and resolver override | `dns.nix` |
| Matrix stack / extra state wiring | `matrix.nix` |
| Reusable native services | `../../profiles/server/*.nix` |
| Quadlet apps imported by whale | `../../apps/*/default.nix` |

## CONVENTIONS

- Put new config in the narrowest place that fits:
  - reusable native service → `profiles/server/`
  - reusable Quadlet app → `apps/`
  - whale-only topology or whale-only service glue → local `machines/whale/*.nix`
- `default.nix` owns the large import list plus bridge/NAT/WireGuard/Yggdrasil/Nebula topology. Treat it as a high-blast-radius file.
- Some services define their own nginx vhosts in their module/app file; host-local routes and shared ingress helpers live in `default.nix`. Follow the existing service family before adding another vhost.
- `makeHost` / `makeAveryanHost` are the local vhost helpers in `default.nix`; reuse them for new whale-local host routes.
- `whale` is the Nebula lighthouse: `networking.nebula-averyan.isLighthouse = true` belongs here only.
- `mail.nix` uses a full NixOS `containers.*` container on the `vms` bridge. Do not default to that pattern for new services; most new containerized services belong in `apps/`.
- `dns.nix` disables `systemd-resolved` on whale and replaces it with CoreDNS. That override is whale-specific.
- Commented imports in `default.nix` are intentional disabled services; do not delete them as cleanup.

## NETWORK TOPOLOGY

- `physWan` and `physLan` are bridged into `wan0` and `lan0`.
- `vms` is the NixOS-container bridge (`192.168.12.0/24`).
- `yggbr` and `wgavbr` are routing bridges for Yggdrasil and WireGuard policy routing.
- Routing table `700` is the VPN policy-routing table used by `wgav`; do not change the table number casually.

## APPS VS LOCAL SERVICES

- Whale is the only machine importing `../../apps/*`.
- Before adding a new imported app, check `apps/AGENTS.md` for subnet allocation and shared app patterns.
- If a service needs whale-specific networking, host mounts, or NixOS container features, document why it is local instead of reusable.

## ANTI-PATTERNS

- Do not copy whale's DNS override or lighthouse settings onto other machines.
- Do not add new containerized services inline in `machines/whale/default.nix`; prefer `apps/` or `profiles/server/` unless the service is truly whale-specific.
- Do not change bridge names, policy-routing table `700`, or container/network addresses without reading the whole host topology first.
