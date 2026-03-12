# SERVER PROFILES KNOWLEDGE BASE

## OVERVIEW

`profiles/server/` is for reusable native NixOS services used mainly by whale.
Use this tree for host services; use `apps/` for reusable Quadlet container apps.

## WHERE TO LOOK

| Need | File |
|------|------|
| Global web defaults | `nginx.nix` |
| ACME / wildcard certs | `acme.nix` |
| PostgreSQL baseline | `pgsql.nix` |
| Standard persisted service pattern | `vaultwarden.nix`, `forgejo.nix` |
| Hardened custom bot service | `avtor24bot.nix` |
| Hybrid host-coupled container exception | `hass.nix` |

## CONVENTIONS

- One file usually represents one reusable service/profile imported from `machines/whale/default.nix`.
- Stateful services declare `persist.state.dirs` explicitly. Do not assume `/var/lib/<service>` survives reboots otherwise.
- Use static UIDs/GIDs for service users. If a service defaults to `DynamicUser`, disable it with `lib.mkForce false` before persisting its data.
- Check existing UID/GID assignments before adding a new one; collisions are not acceptable.
- Internal service ports usually open on `networking.firewall.interfaces."nebula.averyan".allowedTCPPorts`, not the global firewall.
- Public HTTPS services use `services.nginx.virtualHosts` with `useACMEHost`, not ad-hoc certificate wiring.

## NGINX / ACME RULES

- `nginx.nix` uses `pkgs.angie`, not `pkgs.nginx`.
- `forceSSL = true` is injected by default for nginx vhosts. Override it to `false` only with `lib.mkForce`.
- Valid `useACMEHost` values are defined in `acme.nix`: `averyan.ru`, `neutrino.su`, and `memexpert.net`.

## DATABASE-BACKED SERVICES

- PostgreSQL-backed services usually declare `ensureDatabases`, `ensureUsers`, and `systemd.services.<svc>.requires/after = [ "postgresql.service" ]` in the same file.
- Follow `vaultwarden.nix` and `forgejo.nix` for the normal pattern.

## SECRETS / HARDENING

- Shared server secrets usually come from `"${secrets}/creds/..."` or `"${secrets}/accounts/..."`.
- For custom bots or bespoke binaries, start from the hardened `systemd` pattern in `avtor24bot.nix`.
- `hass.nix` is a rare hybrid that mixes host service concerns with Quadlet; do not treat that as the default path.

## ANTI-PATTERNS

- Do not move reusable native services into `apps/` just because they run only on whale today.
- Do not rely on `DynamicUser` when the service keeps persistent data.
- Do not expose internal-only services on the global firewall when Nebula exposure is enough.
