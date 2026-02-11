# 🧊 AveryanAlex's NixOS Configuration

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![nixfmt](https://img.shields.io/badge/formatted%20with-nixfmt-5277C3)](https://github.com/NixOS/nixfmt)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

> A declarative, reproducible, and version-controlled NixOS infrastructure.

## 🏗️ Architecture

This is a **NixOS flake** configuration built with:

- **Declarative**: Entire system state defined in code
- **Reproducible**: Same configuration produces identical systems
- **Modular**: Shared profiles and roles across machines
- **Secure**: Secrets managed with `ragenix` (agenix)

## 🖥️ Fleet

| Machine | Role | Architecture | Hardware |
|---------|------|--------------|----------|
| **🐊 Alligator** | Main Desktop PC | `x86_64-linux` | AMD Ryzen 7 5800X · RX 6800 XT · 32GB RAM |
| **🐋 Whale** | Home Server | `x86_64-linux` | Xeon E5-2696v3 · 64GB RAM · 25TB+ storage |
| **🦎 Lizard** | Dacha Server | `aarch64-linux` | Raspberry Pi 4B · 8GB RAM |
| **🐹 Hamster** | Laptop | `x86_64-linux` | — |

## 🎨 Desktop Environment

Currently using **GNOME**.

### Shell Stack

| Tool | Purpose |
|------|---------|
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart cd command |
| [eza](https://github.com/eza-community/eza) | Modern ls replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder |
| [direnv](https://direnv.net/) | Directory-specific env vars |

## 🚀 Server Infrastructure

Whale runs various self-hosted services:

### Core Services
- **🔐 Vaultwarden** — Password manager
- **📧 Mail server** — Complete mail stack (postfix, dovecot, rspamd)
- **💬 Matrix** — Decentralized chat (Synapse)
- **☁️ Nextcloud** — File sync & collaboration
- **🔍 SearXNG** — Privacy-respecting metasearch

### Media & Downloads
- **🎬 qBittorrent** — BitTorrent client
- **🎵 Navidrome** — Music streaming

### Monitoring & Tools
- **📊 Grafana** — Metrics & dashboards
- **⏱️ Uptime Kuma** — Service monitoring
- **🔔 ntfy** — Push notifications
- **🤖 Telegram Bots** — Various automation bots

### Development
- **🗃️ Forgejo** — Self-hosted Git service
- **🐳 Docker/Podman** — Container runtime
- **⚡ Remote builders** — Distributed Nix builds

## 📁 Repository Structure

```
.
├── 📂 machines/           # Machine-specific configurations
│   ├── alligator/        # Main desktop PC
│   ├── whale/            # Home server
│   ├── lizard/           # Dacha server (Raspberry Pi 4)
│   └── hamster/          # Laptop
│
├── 📂 roles/              # High-level system roles
│   ├── desktop/          # Desktop environment (GNOME, apps)
│   ├── server.nix        # Base server configuration
│   └── minimal/          # Minimal base system
│
├── 📂 profiles/           # Reusable configuration units
│   ├── gui/              # GUI apps
│   ├── shell/            # Shell config (zsh, tools)
│   ├── apps/             # Desktop applications
│   ├── server/           # Server services
│   └── *.nix             # Misc profiles
│
├── 📂 modules/            # Custom NixOS modules
├── 📂 hardware/           # Hardware-specific modules
├── 📂 secrets/            # Encrypted secrets (agenix)
└── 📂 dev/                # Development shell
```

## 🔒 Secrets Management

Secrets are encrypted with [agenix](https://github.com/ryantm/agenix) / [ragenix](https://github.com/yaxitech/ragenix).

## 🌐 Network

- **Nebula mesh VPN** — Secure overlay network between all machines
- **Yggdrasil** — Experimental mesh networking

## 📝 License

MIT — Feel free to borrow ideas and code for your own NixOS journey!

---

<p align="center">
  <sub>Built with ❄️ Nix · <a href="https://github.com/averyanalex">@averyanalex</a></sub>
</p>
