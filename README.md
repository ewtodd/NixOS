# NixOS Multi-Host Configuration
<!---->
This repository manages **NixOS** systems with multiple hosts and user profiles.
<!---->
## Overview
<!---->
The configuration is organized into three main layers:
<!---->
- **modules/** - System-level configuration (desktop env, hardware, security, services)
- **home-manager/** - User-level configuration (packages, theming, desktop settings)
- **hosts/** - Per-host specific configuration
<!---->
```
/etc/nixos/
├── flake.nix                           # Main entry point with mkNixSystem helper
├── modules/
│   ├── default.nix                     # systemOptions definitions & imports
│   ├── desktopEnvironment/             # Niri compositor & DMS shell
│   ├── hardware/                       # Graphics, audio, fingerprint, etc.
│   ├── packages/                       # System packages
│   ├── security/                       # Security hardening
│   └── services/                       # System services
├── home-manager/
│   ├── default.nix                     # Main home-manager entry point
│   ├── profiles/{work,play,root}.nix   # User profiles
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
- **server-nu** - Router, AdGuard, reverse proxy, dynamic DNS
- **server-mu** - SSH bastion, Nextcloud, Minecraft, LiteLLM proxy
- **anton** - ZFS storage server
- **son-of-anton** - AI model server (128GB AMD Strix Halo)
```
<!---->
## Important Notes
<!---->
### `systemOptions`
<!---->
All hosts have access to `systemOptions` defined in `modules/default.nix`:
<!---->
```nix
systemOptions = {
  owner.e.enable = true;                # Owner identification
  deviceType.laptop.enable = true;      # Device type
  graphics.amd.enable = true;           # Graphics drivers
};
```
This determines which graphics drivers are enabled, whether custom security settings should be applied, whether to apply chromebook specific patches, etc.
<!---->
### Profile System
<!---->
Users are organized into **work**, **play**, or **root** profiles:
<!---->
```nix
# home-manager/profiles/work.nix
{ lib, ... }:
{
  imports = [
    ../packages
    ../desktopEnvironment
    ../theming
    ../xdg
  ];
  Profile = "work";
}
```
<!---->
- **Work:** clang-tools, slack, tools for nuclear physics data analysis
- **Play:** signal-desktop, mangohud, android-tools, mumble, gaming tools
- **Root:** Minimal profile without desktop environment configurations
<!---->
Set this option per-user in `hosts/{hostname}/home.nix` via profile import.
<!---->
## Desktop Environment
<!---->
- **Compositor:** niri (scrollable tiling Wayland)
- **Shell:** DankMaterialShell (DMS)
- **Greeter:** DMS greeter
- **Config:** `home-manager/desktopEnvironment/`
<!---->
## Shell & Terminal

- **Shell:** bash
- **Prompt:** Starship
- **Terminal:** Kitty
- **Editor:** Neovim (configured via nixvim)

Configuration in `home-manager/packages/shell/`.

## AI Assistant

`opencode` CLI is configured for e-owner devices with:

- LiteLLM provider pointing to `https://llm.ethanwtodd.com/v1`
- All 6 models accessible (`auto` routing + explicit selection)
- MCP nixos integration for Nix/NixOS package and option lookups
- Pre-loaded house rules for ROOT/C++ development (explicit types, no modern C++ in ROOT code)
- Bash activation loads `LITELLM_MASTER_KEY` from agenix secret
<!---->
## Theming
<!---->
Colors managed via **base16.nix** with schemes from `pkgs.base16-schemes` on a per-profile basis.
<!---->
```nix
scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
```
<!---->
## Adding a New Host
<!---->
```bash
nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```
<!---->
Create `hosts/new-host/configuration.nix` with systemOptions, then add to flake.nix:
```nix
nixosConfigurations.new-host = mkNixSystem { hostname = "new-host"; };
```
<!---->
## Modifying Configuration
<!---->
### Add System Feature
1.
Add option to `modules/default.nix`
2.
Create module in `modules/`
3.
Enable in host's `configuration.nix`
<!---->
### Add User Package
Edit `home-manager/packages/default.nix`.
<!---->
### Modify Shell Aliases
Edit `home-manager/packages/shell/default.nix` for bash aliases.
<!---->
## Binary Cache

**e-desktop** serves its nix store as a binary cache so other hosts can pull pre-built packages instead of compiling from source. This is especially useful for git-versioned packages like niri, quickshell, and DMS.

- **Server:** `nix-serve-ng` on e-desktop, exposed via Caddy reverse proxy on server-nu
- **Clients:** All other hosts are configured as substituters via `systemOptions.services.binaryCache.consume`
- **URL:** `https://cache.ethanwtodd.com`
<!---->
### Setup
<!---->
The signing keypair lives at `/etc/nix/cache-priv-key.pem` (server) and `/etc/nix/cache-pub-key.pem` (public key baked into client config). To regenerate:
```bash
sudo nix-store --generate-binary-cache-key e-desktop /etc/nix/cache-priv-key.pem /etc/nix/cache-pub-key.pem
```
If regenerated, update the public key in `modules/services/default.nix` and rebuild all clients.
<!---->
Tailscale Funnel must be enabled in the e-tailnet ACL (`nodeAttrs` with `funnel` attr) and started once on e-desktop:
```bash
sudo tailscale funnel --bg 5000
```

## AI/LLM Infrastructure

The fleet includes dedicated AI servers running llama-swap and LiteLLM:

- **son-of-anton** (AMD Strix Halo 128GB): Multi-model llama-swap server with Vulkan backend
  - `gpt-oss-120b` - big-moe / orchestrator default (65536 context)
  - `qwen3-coder-next` - Qwen3-Coder-Next-80B-A3B smart-coder (65536 context)
  - `qwen3-30b-a3b` - ultra-fast general tier ~100 t/s (65536 context)
  - `qwen3.5-122b` - orchestrator alternate Qwen3.5-122B-A10B (65536 context)
  - `minimax-m2.5` - ~230B capability experiment (32768 context)

- **e-desktop** (RTX 5080 16GB): Fast coder model via CUDA backend
  - `qwen-coder` - Qwen2.5-Coder-14B (32768 context, ttl=300s)

- **server-mu**: LiteLLM proxy with content-based classifier routing
  - Routes `auto` model to appropriate tier based on request complexity
  - Fallback chain: fast-coder → big-moe (when 5080 busy/unloaded)
  - Single entry point: `https://llm.ethanwtodd.com/v1`

The `opencode` CLI tool is pre-configured to use this infrastructure via the LiteLLM endpoint.
<!---->
## Development Environments
<!---->
```bash
init-dev-env          # General development
init-latex-env        # LaTeX
init-geant4-env       # Geant4 physics simulation
init-analysis-env     # ROOT analysis using custom library
```
<!---->
## Roadmap
- [x] Switch from nix-colors to base16.nix since that is actually maintained
- [x] Move geant4 development environment into its own repo as a flake
- [x] Expose nixvim configuration as a runnable package (`nix run`)
- [x] Set up multi-model LLM infrastructure with llama-swap + LiteLLM
- [x] Add opencode AI assistant with fleet model access
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer)
