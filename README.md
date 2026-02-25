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
<!---->
- **Shell:** bash
- **Prompt:** Starship
- **Terminal:** Kitty
- **Editor:** Neovim (configured via nixvim)
<!---->
Configuration in `home-manager/packages/shell/`.
<!---->
## Theming
<!---->
Colors managed via **nix-colors** on a per-profile basis.
<!---->
```nix
colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
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
- [x] Move geant4 development environment into its own repo as a flake
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [x] Expose nixvim configuration as a runnable package (`nix run`)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer)
