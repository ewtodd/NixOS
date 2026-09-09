# NixOS Multi-Host Configuration
This repository manages **NixOS** systems with multiple hosts and user profiles.
<!---->
## Overview
The configuration is organized into three main layers:
- **modules/** - System-level configuration (desktop env, hardware, security, services)
- **home-manager/** - User-level configuration (packages, theming, desktop settings)
- **hosts/** - Per-host specific configuration
```
/etc/nixos/
├── flake.nix                           # Main entry point with mkNixSystem helper
├── modules/
│   ├── default.nix                     # systemOptions definitions & imports
│   ├── desktopEnvironment/             # Niri compositor & DMS shell
│   ├── hardware/                       # Graphics, audio, fingerprint, etc.
│   ├── packages/                       # System packages
│   ├── secrets/                        # agenix-encrypted secrets
│   ├── security/                       # Security hardening
│   └── services/                       # System services
├── home-manager/
│   ├── default.nix                     # Main home-manager entry point
│   ├── profiles/{work,play,root,server}.nix # User profiles
│   ├── packages/                       # nixvim, git, kitty, zathura, etc.
│   │   ├── nixvim/                     # Neovim configuration
│   │   ├── shell/                      # bash + starship
│   │   └── ...                         # Other package configs
│   ├── system-options/                 # Profile & owner options
│   ├── desktopEnvironment/             # Niri & DMS settings
│   │   ├── dms/                        # DMS colors, plugins, dsearch
│   │   └── niri/                       # Niri keybinds & window rules
│   ├── theming/                        # GTK & Qt themes
│   └── xdg/                            # XDG directories & MIME types
└── hosts/{hostname}/
    ├── configuration.nix               # Host system config (enables systemOptions)
    ├── hardware-configuration.nix      # Hardware-specific config
    ├── environment.nix                 # Kernel & environment settings
    └── home.nix                        # User definitions (imports profiles)
Hosts:
- **v-desktop, v-laptop** - AMD/Intel workstations (v-owner)
- **e-desktop, e-laptop** - NVIDIA/Intel workstations (e-owner, full services)
- **nu** - Router, AdGuard, reverse proxy, dynamic DNS, Prometheus & Grafana
- **mu** - SSH bastion, Nextcloud, Minecraft, Signal bot backend
- **anton** - headless server (no inference role): raidz2 tank with borg backup server,
  zfs-metrics, Jellyfin media server (Intel QSV transcoding, LAN only)
- **tony** - living room kiosk: cage + Firefox kiosk on 4K 30 Hz, landing page of
  stream/site tiles, nightly 04:00 session restart to drop stale cookies
- **son-of-anton** - vLLM (Qwen3.8-27B-FP8, TP=2) + ds4 (DeepSeek-V4-Flash-Vision, ROCm)
- **oracle** - model router & tooling host (aarch64): llama-swap, LiteLLM MCP gateway,
  SearXNG, Open WebUI (ai.ethanwtodd.com)
```
## Important Notes
### `systemOptions`
All hosts have access to `systemOptions` defined in `modules/default.nix`:
```nix
systemOptions = {
  owner.e.enable = true;                # Owner identification
  deviceType.laptop.enable = true;      # Device type
  graphics.amd.enable = true;           # Graphics drivers
};
```
This determines which graphics drivers are enabled, whether custom security settings should be applied, whether to apply chromebook specific patches, etc.
### Profile System
Users are organized into **work**, **play**, **root**, or **server** profiles.
A profile just sets the `Profile` option; package and program selection is gated
on it in `home-manager/packages/default.nix`:
```nix
# home-manager/profiles/work.nix
{ lib, osConfig, ... }:
{
  imports = [ ../default.nix ];
  Profile = "work";
}
```
- **Work:** slack, thunderbird, lisepp, SRIM, rootbrowse, gost — tools for nuclear physics data analysis
- **Play:** signal-desktop, mangohud, gamescope + lsfg-vk, android-tools, prismlauncher, gaming tools
- **Root:** Minimal profile without desktop environment configurations
- **Server:** Minimal headless profile (btop, fastfetch, nixvim, ripgrep)
Set this option per-user in `hosts/{hostname}/home.nix` via profile import.
## Desktop Environment
- **Compositor:** niri (scrollable tiling Wayland)
- **Shell:** DankMaterialShell (DMS)
- **Greeter:** DMS greeter
- **Config:** `home-manager/desktopEnvironment/`
- **tony** is the exception: bare cage as a single-window kiosk compositor
## Shell & Terminal
- **Shell:** bash
- **Prompt:** Starship
- **Terminal:** Kitty
- **Editor:** Neovim (configured via nixvim)
Configuration in `home-manager/packages/shell/`.
## Theming
Colors managed via **base16.nix** with schemes from `pkgs.base16-schemes` on a per-profile basis.
```nix
scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
```
## Adding a New Host
```bash
nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```
Create `hosts/new-host/configuration.nix` with systemOptions, then add to flake.nix:
```nix
nixosConfigurations.new-host = mkNixSystem { hostname = "new-host"; };
```
## Modifying Configuration
### Add System Feature
1.
Add option to `modules/default.nix`
2.
Create module in `modules/`
3.
Enable in host's `configuration.nix`
### Add User Package
Edit `home-manager/packages/default.nix`.
### Modify Shell Aliases
Edit `home-manager/packages/shell/default.nix` for bash aliases.
## Binary Cache
**e-desktop** serves its nix store as a binary cache so other hosts can pull pre-built packages instead of compiling from source.
This is especially useful for git-versioned packages like niri, quickshell, and DMS.
- **Server:** `nix-serve-ng` on e-desktop, exposed via Caddy reverse proxy on nu
- **Clients:** All other hosts are configured as substituters via `systemOptions.services.binaryCache.consume`
- **URL:** `https://cache.ethanwtodd.com`
## AI Infrastructure
The fleet distributes inference and gateway services across dedicated hosts:
- **son-of-anton** (2x AMD R9700 Pro 32GB + Strix Halo iGPU):
  - **vLLM** (:8100): Qwen3.8-27B-FP8, tensor-parallel across the two R9700s, MTP
    speculative decoding, 262k context, fp8 KV cache
  - **ds4** (:8050): DeepSeek-V4-Flash-Vision on the Strix Halo iGPU (ROCm),
    512k context with 512 GB on-disk KV at /scratch
- **e-desktop** runs the **son-of-anton** agent (github.com/ewtodd/son-of-anton),
  successor to temple-server: one system service per account on a shared Signal
  number, and each account's CLI shares its service's session state
- **oracle** (aarch64, 8 cores / 7 GB) hosts the model router and tooling:
  - **llama-swap** (Vulkan backend): little-titles (Little-Titles Q8_0, always
    resident — title generation for the son-of-anton accounts) + bge-m3 embeddings
  - **LiteLLM** proxy (:4000): routes son-of-anton, opencode, and Open WebUI to
    vLLM and ds4 on son-of-anton, llama-swap on oracle, and the hosted DeepSeek API
  - **MCP gateway** (mounted at /mcp) aggregating stdio servers: `fetch` (URL
    retrieval), `searxng` (web search), `nixos` (Nix/NixOS lookups), `arxiv`,
    and `context7`
  - **SearXNG** metasearch, backing the searxng MCP
  - **Open WebUI** at `ai.ethanwtodd.com` (behind Anubis PoW; models via litellm)
## Deployment (Colmena)
The fleet is deployed with [Colmena](https://github.com/zhaofengli/colmena).
The hive (`colmena` / `colmenaHive` flake outputs) reuses each host's NixOS
modules, so it never drifts from `nixosConfigurations`.
**e-desktop is the build host** — it builds every closure and pushes the result,
so the servers and laptops never compile.
```bash
colmena apply --on @server   # build on e-desktop, push to the 5 servers
colmena apply-local          # rebuild the local workstation (e-desktop / e-laptop)
colmena apply --on anton     # a single node
```
- **Scope:** the 8 e-owner nodes (v-devices excluded for now).
  The headless servers and the tony kiosk are pushed over SSH; the two
  workstations deploy locally (`apply-local`, which also sidesteps e-laptop's
  dynamic IP).
- **Auth:** a key-only `deploy` user (`systemOptions.services.deploy.enable`)
  with scoped NOPASSWD sudo (only the activation commands) and nix trusted-user.
  Connections jump through the `mu` bastion via the `*-deploy` SSH
  aliases, so deploys work on- and off-LAN.
- **Bootstrap:** the `deploy` user is created *by* this config, so a brand-new
  server must be switched once by other means before Colmena can take it over.
## Development Environments
```bash
init-dev-env          # General development
init-latex-env        # LaTeX
init-geant4-env       # Geant4 physics simulation
init-analysis-env     # ROOT analysis using custom library
```
## Roadmap
- [x] Switch from nix-colors to base16.nix since that is actually maintained
- [x] Move geant4 development environment into its own repo as a flake
- [x] Expose nixvim configuration as a runnable package (`nix run`)
- [x] Set up multi-model LLM infrastructure
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer)
