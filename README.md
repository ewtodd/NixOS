# NixOS Multi-Host Configuration
This repository manages **NixOS** systems with multiple hosts and user profiles.

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
- **server-mu** - SSH bastion, Nextcloud, Minecraft
- **anton** - ZFS storage server
- **son-of-anton** - AI stack (128GB AMD Strix Halo, 32GB R9700 eGPU): llama-swap models, LiteLLM proxy + MCP gateway, librechat, SearXNG
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
Users are organized into **work**, **play**, or **root** profiles:
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
- **Work:** clang-tools, slack, tools for nuclear physics data analysis
- **Play:** signal-desktop, mangohud, android-tools, mumble, gaming tools
- **Root:** Minimal profile without desktop environment configurations
Set this option per-user in `hosts/{hostname}/home.nix` via profile import.
## Desktop Environment
- **Compositor:** niri (scrollable tiling Wayland)
- **Shell:** DankMaterialShell (DMS)
- **Greeter:** DMS greeter
- **Config:** `home-manager/desktopEnvironment/`
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
- **Server:** `nix-serve-ng` on e-desktop, exposed via Caddy reverse proxy on server-nu
- **Clients:** All other hosts are configured as substituters via `systemOptions.services.binaryCache.consume`
- **URL:** `https://cache.ethanwtodd.com`
## AI Infrastructure
The fleet includes a dedicated AI server running llama-swap and LiteLLM:
- **son-of-anton** (AMD Strix Halo 128GB): Multi-model llama-swap server with Vulkan backend; primarily used for large MoE models
- **son-of-son-of-anton, or antonino** (AMD R9700 32GB as eGPU on son-of-anton): Also connected to llama-swap server; used for dense models + to improve concurrency
- **son-of-anton/antonino** also hosts the rest of the AI stack (consolidated — every hop is localhost):
  - **LiteLLM proxy**, single entry point: `https://llm.ethanwtodd.com/v1`
  - **MCP gateway** at `https://llm.ethanwtodd.com/mcp/` (auth via `Authorization: Bearer <key>`), aggregating three stdio servers run by the proxy: `fetch` (URL retrieval), `searxng` (`web_search` over the local SearXNG), and `nixos` (Nix/NixOS lookups via `mcp-nixos`). Consumed by both qwen-code.
  - **SearXNG** metasearch, localhost-only, backing the searxng MCP.
### Coding Agent

**opencode** (e-workstations via `home-manager/packages/opencode`) — coding
CLI/TUI pointed at the LiteLLM endpoint, default model **Qwen3.6-27b**.
MCP servers are served via the remote LiteLLM MCP gateway at
`https://llm.ethanwtodd.com/mcp/`, aggregating `fetch`, `searxng`, `nixos`,
`arxiv`, and `context7`. The wrapper sources `LITELLM_MASTER_KEY` from the
agenix secret at launch.

#### Specialized Agents

Opencode dispatches to specialized subagents for specific tasks:

| Agent | Model | Role |
|---|---|---|
| **code-reviewer** | `qwen3.6-35b-a3b-coding` | Reviews code for bugs, security, performance, and maintainability. Read-only. |
| **security-auditor** | `qwen3.5-122b-a10b` | Deep security audit for auth, crypto, secrets, and user input. Read-only. |
| **debugger** | `deepseek-v4-flash-high` | Systematic root-cause analysis for broken or unclear behavior. |
| **architect** | `qwen3.5-122b-a10b` | High-level design decisions, module boundaries, and API contracts. Read-only. |
| **test-writer** | `fast-qwen3.6-27b` | Generates comprehensive tests after feature or bug-fix implementation. |
| **refactorer** | `deepseek-v4-flash-max` | Improves code structure without changing behavior. |
| **docs-writer** | `fast-qwen3.6-27b` | Writes documentation, docstrings, and READMEs. |

## Deployment (Colmena)
The fleet is deployed with [Colmena](https://github.com/zhaofengli/colmena).
The hive (`colmena` / `colmenaHive` flake outputs) reuses each host's NixOS
modules, so it never drifts from `nixosConfigurations`.
**e-desktop is the build host** — it builds every closure and pushes the result,
so the servers and laptops never compile.
```bash
colmena apply --on @server   # build on e-desktop, push to the 4 servers
colmena apply-local          # rebuild the local workstation (e-desktop / e-laptop)
colmena apply --on anton     # a single node
```
- **Scope:** the 6 e-owner nodes (v-devices excluded for now).
The headless servers are
  pushed over SSH; the two workstations deploy locally (`apply-local`, which
  also sidesteps e-laptop's dynamic IP).
- **Auth:** a key-only `deploy` user (`systemOptions.services.deploy.enable`)
  with scoped NOPASSWD sudo (only the activation commands) and nix trusted-user.
  Connections jump through the `server-mu` bastion via the `*-deploy` SSH
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
- [x] Set up multi-model LLM infrastructure with llama-swap + LiteLLM
- [x] Add opencode AI assistant with fleet model access
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer)
