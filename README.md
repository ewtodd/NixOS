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
- **mu** - SSH bastion, Nextcloud, Minecraft, Signal bot backend, and the AI front: maitred,
  SearXNG, Open WebUI (ai.ethanwtodd.com)
- **anton** - headless server (no inference role): raidz2 tank with borg backup server,
  zfs-metrics, Jellyfin media server (Intel QSV transcoding, LAN only)
- **tony** - living room kiosk: cage + Firefox kiosk on 4K 30 Hz, landing page of
  stream/site tiles, nightly 04:00 session restart to drop stale cookies
- **son-of-anton** - LLM inference, one `llm-mode` at a time: DeepSeek-V4-Flash (unholy), or
  Qwen3.8-27B (Radiance) + Qwen3.8-Flash-Next (gufo)
- **fiona** - small-model inference on an Arc A770M (16 GB): llama.cpp (Vulkan) for title
  generation and EmbeddingGemma 2 embeddings, behind maitred
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
- **son-of-anton** (2x AMD R9700 Pro 32GB + Strix Halo iGPU) serves one mode at a time;
  `llm-mode ds4|qwen|status` switches between them without a redeploy:
  - **ds4** — **unholy** (:8200, github.com/ewtodd/unholy): DeepSeek-V4-Flash across both
    R9700s and the iGPU, 512k context, a 1.5M-token bf16 KV pool shared by up to 8 requests,
    DSpark speculative decoding, prefix-cache snapshots
  - **qwen** — **[Radiance](https://codeberg.org/StillDeadcode/radiance)** (:8100): Qwen3.8-27B
    FP8 with the DFlash2 drafter, tensor-parallel across the R9700s, 352k context (YaRN), bf16
    KV; built from source by [radiance-nix](https://github.com/ewtodd/radiance-nix) against the
    TheRock ROCm 10.1 SDK unholy pins. Beside it **[gufo](https://github.com/gufo-org/gufo)**
    (:8050): Qwen3.8-Flash-Next (UD-Q4_K_XL with Q5 down-projection and bf16 n-gram overlays)
    on the Strix Halo iGPU, with the MTP draft and vision projector, 262k context
- **fiona** (Arc A770M 16GB) runs llama.cpp on Vulkan, one llama-server systemd unit per model:
  Little-Titles Q8_0 (:8080, title generation for the son-of-anton accounts and Open WebUI)
  and an EmbeddingGemma 2 embedding server (:8082, son-of-anton's memory RAG and Open WebUI)
- **mu** hosts the AI front. `systemOptions.aiFrontAddress` names that host; nu's Caddy and
  the clients point at it, so moving the front is one line:
  - **[maitred](https://github.com/ewtodd/maitred)** (:4002), the gateway every client uses:
    - `/v1` routes son-of-anton, opencode, and Open WebUI to son-of-anton's servers,
      fiona's llama.cpp, and the hosted DeepSeek API, with per-consumer virtual keys. Every model is
      listed with its context window, reasoning efforts, and live status; a request for a
      model of the mode that is not loaded gets a 503 naming what to use instead
    - `/mcp` aggregates stdio MCP servers per key: `fetch` (URL retrieval), `searxng` (web
      search), `nixos` (Nix/NixOS lookups), `arxiv`, and `context7`
  - **SearXNG** metasearch, backing the searxng MCP and son-of-anton's web search
  - **Open WebUI** at `ai.ethanwtodd.com` (behind Anubis PoW; models via maitred)
- **e-desktop** runs the **son-of-anton** agent (github.com/ewtodd/son-of-anton),
  successor to temple-server: one system service per account on a shared Signal
  number, and each account's CLI shares its service's session state
## Deployment (Colmena)
The fleet is deployed with [Colmena](https://github.com/zhaofengli/colmena).
The hive (`colmena` / `colmenaHive` flake outputs) reuses each host's NixOS
modules, so it never drifts from `nixosConfigurations`.
**e-desktop is the build host** — it builds every closure and pushes the result,
so the servers and laptops never compile.
```bash
colmena apply --on @server   # build on e-desktop, push to the 5 servers
colmena apply --on anton     # a single node
nrs                          # rebuild the local workstation (e-desktop / e-laptop): nh os switch /etc/nixos
```
- **Scope:** the 8 e-owner nodes (v-devices excluded for now).
  The headless servers and the tony kiosk are pushed over SSH; the two
  workstations rebuild themselves with `nrs` (`nh os switch /etc/nixos`), which
  also sidesteps e-laptop's dynamic IP.
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
