# CORE ROLE KNOWLEDGE BASE

## OVERVIEW

`roles/core/` is the shared base for nearly every active machine.
Changes here affect system networking, podman, shell defaults, module imports, and the `hm` Home Manager shorthand.

## WHERE TO LOOK

| Need | File |
|------|------|
| Core composition and imported modules | `default.nix` |
| Network stack defaults | `network.nix` |
| Podman / Quadlet substrate | `podman.nix` |
| Global system profiles | `system.nix` |
| Shell tool composition | `shell/default.nix` + child files |

## CONVENTIONS

- `default.nix` wires in `inputs.nixcfg`, `inputs.home-manager`, `inputs.quadlet-nix`, and the custom modules from `inputs.self.nixosModules.modules.*`.
- `hm` is provided by the external `nixcfg` flake and targets `home-manager.users.alex`; it is not defined in this repo.
- `system.nix` is the profile bus for shared non-role-specific profiles.
- Add shell tools as separate files under `shell/` and import them from `shell/default.nix`; do not keep growing one monolithic shell file.
- If a setting is truly cross-machine and not obviously desktop-only or server-only, this is usually the right subtree.

## NETWORKING INVARIANTS

- `networking.useNetworkd = true`
- `networking.useDHCP = false`
- `services.resolved.enable = true`
- `services.avahi.enable = false`
- `networking.nftables.flushRuleset = false`

These are deliberate repo-wide defaults. Whale has local DNS exceptions, but core itself is built around `systemd-networkd` + `systemd-resolved` + nftables.

## TPROXY / PODMAN NOTES

- `networking.tproxy.enable = true` is on at the core layer. Output-mode routing is opt-in elsewhere (`roles/desktop`, `machines/whale`).
- Podman network naming convention: `pme-*` for external-facing app networks, `pmi-*` for internal-only networks.
- Network ranges are split deliberately:
  - `10.88.0.0/16` default podman network
  - `10.89.0.0/16` auto-assigned user-defined pools
  - `10.90.X.0/24` explicitly managed app networks
- Keep `virtualisation.containers.containersConf.settings.network.firewall_driver = lib.mkForce "none"`; podman relies on the repo's nftables setup.

## ANTI-PATTERNS

- Do not re-enable legacy DHCP or Avahi here.
- Do not flip `networking.nftables.flushRuleset` to `true`; podman depends on it staying `false`.
- Do not duplicate core module imports from machines or profiles unless there is a very explicit reason.
