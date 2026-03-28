# AveryanAlex's NixOS Configuration

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![nixfmt](https://img.shields.io/badge/formatted%20with-nixfmt-5277C3)](https://github.com/NixOS/nixfmt)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Declarative, reproducible NixOS infrastructure managed as a single flake.
Machines auto-discovered from `machines/`, secrets encrypted with [ragenix](https://github.com/yaxitech/ragenix), deployed with [Colmena](https://github.com/zhaofengli/colmena).

## 🖥 Machines

| Host | Purpose | Arch | Hardware |
|------|---------|------|----------|
| **alligator** | Main desktop | `x86_64` | AMD Ryzen 7 5800X, RX 6800 XT, 32 GB |
| **hamster** | Laptop | `x86_64` | ThinkBook 14 |
| **whale** | Home server | `x86_64` | Xeon E5-2696v3, 64 GB, 25 TB+ storage |
| **lizard** | Dacha server | `aarch64` | Raspberry Pi 4B, 8 GB |

## 🖱 Desktop

- **Compositor** &mdash; [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland)
- **Shell** &mdash; Zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k), [zoxide](https://github.com/ajeetdsouza/zoxide), [fzf](https://github.com/junegunn/fzf), [eza](https://github.com/eza-community/eza), [atuin](https://github.com/atuinsh/atuin), [direnv](https://direnv.net/)
- **Editors** &mdash; [VS Code](https://code.visualstudio.com/), [Zed](https://zed.dev/)
- **AI tools** &mdash; [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [Codex](https://openai.com/index/codex/), [OpenCode](https://github.com/sst/opencode)

## 🐋 Server (whale)

Whale runs a mix of native NixOS services and Podman containers via [Quadlet](https://github.com/SEIAROTg/quadlet-nix).

**🏗 Infrastructure**
- [Nginx](https://nginx.org/) &mdash; reverse proxy + ACME certificates
- [CoreDNS](https://coredns.io/) &mdash; internal DNS
- [PostgreSQL](https://www.postgresql.org/) / [MySQL](https://www.mysql.com/)

**💬 Communication**
- [Simple NixOS Mailserver](https://gitlab.com/simple-nixos-mailserver/nixos-mailserver) &mdash; full mail stack (Postfix, Dovecot, Rspamd)
- [Matrix Synapse](https://github.com/element-hq/synapse) &mdash; decentralized chat

**☁️ Apps**
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden) &mdash; password manager
- [Nextcloud](https://nextcloud.com/) &mdash; file sync & collaboration
- [Forgejo](https://forgejo.org/) &mdash; Git forge
- [SearXNG](https://github.com/searxng/searxng) &mdash; metasearch engine
- [Radicale](https://radicale.org/) &mdash; CalDAV / CardDAV
- [Home Assistant](https://www.home-assistant.io/) &mdash; home automation
- [ntfy](https://ntfy.sh/) &mdash; push notifications

**🎵 Media**
- [Navidrome](https://www.navidrome.org/) &mdash; music streaming
- [qBittorrent](https://www.qbittorrent.org/) &mdash; BitTorrent client
- [Lidarr](https://lidarr.audio/) &mdash; music collection manager
- [Prowlarr](https://prowlarr.com/) &mdash; indexer manager
- [Slskd](https://github.com/slskd/slskd) &mdash; Soulseek client

**🤖 AI / Dev**
- [LiteLLM](https://github.com/BerriAI/litellm) &mdash; LLM proxy
- [Qdrant](https://qdrant.tech/) &mdash; vector database
- [Woodpecker CI](https://woodpecker-ci.org/) &mdash; continuous integration
- [Pterodactyl](https://pterodactyl.io/) &mdash; game server panel

**📊 Analytics**
- [Matomo](https://matomo.org/) &mdash; web analytics
- [Wakapi](https://wakapi.dev/) &mdash; coding time tracking

**🔧 Other**
- [BorgBackup](https://www.borgbackup.org/) &mdash; deduplicating backups
- [Syncthing](https://syncthing.net/) &mdash; file synchronization
- [I2P](https://geti2p.net/) &mdash; anonymous network
- [WebTLO](https://github.com/keepers-team/webtlo) &mdash; torrent tracker management
- Remote Nix builder

## 🦎 Server (lizard)

Home automation at the dacha.

- [Home Assistant](https://www.home-assistant.io/) &mdash; home automation
- [Frigate](https://frigate.video/) &mdash; NVR with object detection
- [Mosquitto](https://mosquitto.org/) &mdash; MQTT broker

## 🌐 Networking

- [Yggdrasil](https://yggdrasil-network.github.io/) mesh overlay between all machines
- [Nebula](https://github.com/slackhq/nebula) VPN (whale is lighthouse)
- WireGuard tunnel on whale
- systemd-networkd everywhere, NetworkManager on laptops

## 📁 Repo structure

```
machines/        Per-host configs (auto-discovered by the flake)
roles/
  core/          Base system, networking, Podman, shell, Home Manager
  desktop/       Desktop stack (imports core + dev)
  dev/           Editors, AI tools, languages, LSPs
  family.nix     Family desktop role (user olga, Russian locale)
  server.nix     Server hardening (watchdog, sysctl, BBR)
profiles/        Reusable opt-in modules (bluetooth, libvirt, printing, ...)
  server/        Native NixOS services for whale
apps/            Quadlet/Podman containers for whale
modules/         Custom NixOS modules (auto-exported)
hardware/        Hardware modules (auto-exported)
secrets/         Encrypted .age files (git submodule)
secrets.nix      Public-key ACL for agenix
```

## 🚀 Usage

```bash
nh os switch              # rebuild current machine
nh os build               # build without switching
./deploy.sh <host> switch # deploy to a remote host
nix flake check           # lint
treefmt                   # format
```

## 📝 License

MIT
