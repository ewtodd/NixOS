# NixOS & nix-darwin Multi-Host Configuration
<!---->
This repository manages both **NixOS** (Linux) and **nix-darwin** (macOS) systems with a unified, cross-platform configuration structure.
The architecture maximizes code reuse while keeping platform-specific concerns isolated.
<!---->
## Overview
<!---->
The configuration is organized into three main layers:
<!---->
1. **modules/** - System-level configuration (common, nixos, darwin)
<!---->
2. **home-manager/** - User-level configuration (common, nixos, darwin)
<!---->
3. **hosts/** - Per-host specific configuration
<!---->
```
/etc/nixos/
├── flake.nix                           # Main entry point with mkNixSystem & mkDarwinSystem helpers
├── modules/
│   ├── common/default.nix              # Cross-platform systemOptions definitions
│   ├── nixos/                          # NixOS: desktop env, hardware, security, services
│   │   ├── desktopEnvironment/         # Niri compositor & DMS shell
│   │   ├── hardware/                   # Graphics, audio, fingerprint, etc.
│   │   ├── packages/                   # System packages
│   │   ├── security/                   # Security hardening
│   │   └── services/                   # System services
│   └── darwin/                         # macOS system configuration
│       ├── homebrew/                   # Homebrew package management
│       └── system-defaults/            # macOS system preferences
├── home-manager/
│   ├── common/                         # Cross-platform user configuration
│   │   ├── profiles/{work,play,root}.nix  # Unified profiles that auto-import platform modules
│   │   ├── packages/                   # nixvim, git, kitty, zathura, etc.
│   │   │   ├── nixvim/                 # Neovim configuration
│   │   │   ├── shell/                  # zsh + starship
│   │   │   └── ...                     # Other package configs
│   │   └── system-options/             # Profile & owner options
│   ├── nixos/                          # NixOS user configuration
│   │   ├── desktopEnvironment/         # Niri & DMS settings
│   │   │   ├── dms/                    # DMS colors, plugins, dsearch
│   │   │   └── niri/                   # Niri keybinds & window rules
│   │   ├── theming/                    # GTK & Qt themes
│   │   └── xdg/                        # XDG directories & MIME types
│   └── darwin/                         # macOS user configuration
│       ├── window-management/          # Window manager configuration
│       │   └── amethyst/               # Amethyst tiling WM
│       └── input/                      # Input device configuration
│           └── karabiner/              # Karabiner-Elements keyboard
└── hosts/{hostname}/
    ├── configuration.nix               # Host system config (enables systemOptions)
    ├── hardware-configuration.nix      # NixOS only
    └── home.nix                        # User definitions (imports profiles)
```
<!---->
## Key Design Patterns
<!---->
### 1. Unified `systemOptions`
<!---->
All hosts have access to `systemOptions` defined in `modules/common/default.nix`:
<!---->
```nix
systemOptions = {
  owner.e.enable = true;                # Owner identification (cross-platform)
  deviceType.laptop.enable = true;      # Device type (cross-platform)
  services.ai.enable = true;            # AI services (cross-platform)
  graphics.amd.enable = true;           # NixOS-specific (ignored on Darwin)
};
```
<!---->
### 2. Profile System
<!---->
Users are organized into **work**, **play**, or **root** profiles that import all platform modules unconditionally:
<!---->
```nix
# home-manager/common/profiles/work.nix
{ lib, ... }:
{
  imports = [
    ../packages
    ../../nixos    # Always imported, only activates on Linux
    ../../darwin   # Always imported, only activates on Darwin
  ];
  Profile = "work";
}
```
<!---->
Each platform module uses `mkIf pkgs.stdenv.isLinux` or `mkIf pkgs.stdenv.isDarwin` internally to control activation.
The **root** profile only imports darwin modules since root users don't need desktop environment configurations.
<!---->
### 3. Platform Detection
<!---->
Modules use `pkgs.stdenv.isLinux` / `isDarwin` with `mkIf` for conditional activation:
<!---->
```nix
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.packages = lib.optionals isLinux [ signal-desktop ]
               ++ lib.optionals isDarwin [ /* macOS packages */ ];
#
  programs.dank-material-shell = lib.mkIf isLinux {
    enable = true;
    # ... NixOS-only configuration
  };
}
```
<!---->
### 4. Safe `osConfig` Access
<!---->
Home-manager modules safely access system options:
<!---->
```nix
{ osConfig ? null, ... }:
let
  hasAI = if osConfig != null
    then osConfig.systemOptions.services.ai.enable
    else false;
in { /* ... */ }
```
<!---->
## Desktop Environments
<!---->
### NixOS
- **Compositor:** niri (scrollable tiling Wayland)
- **Shell:** DankMaterialShell (DMS)
- **Greeter:** DMS greeter
- **Config:** `home-manager/nixos/desktopEnvironment/`
<!---->
### Darwin
- **Window Manager:** Amethyst (tiling)
- **Keyboard:** Karabiner-Elements
- **Config:** `home-manager/darwin/window-management/` & `home-manager/darwin/input/`
- **System:** `modules/darwin/homebrew/` & `modules/darwin/system-defaults/`
<!---->
## Shell & Terminal
<!---->
- **Shell:** zsh (all platforms)
- **Prompt:** Starship
- **Terminal:** Kitty
- **Editor:** Neovim (nixvim)
<!---->
Configuration unified in `home-manager/common/shell.nix`.
<!---->
## Profiles: Work vs Play
<!---->
- **Work:** clang-tools, slack, SRIM, LISE++, VPN aliases (e-owner), research tools
- **Play:** signal-desktop, mangohud, android-tools, mumble, gaming tools
<!---->
Set per-user in `hosts/{hostname}/home.nix` via profile import.
<!---->
## Theming
<!---->
Colors managed via **nix-colors**.
Common schemes:
- Work: `kanagawa`, `atelier-cave`
- Play: `eris`, `harmonic16-dark`
<!---->
```nix
colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
```
<!---->
## Adding a New Host
<!---->
### NixOS
```bash
nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```
<!---->
Create `hosts/new-host/configuration.nix` with systemOptions, then add to flake.nix:
```nix
nixosConfigurations.new-host = mkNixSystem { hostname = "new-host"; };
```
<!---->
### Darwin
Create `hosts/new-darwin/configuration.nix`, then add to flake.nix:
```nix
darwinConfigurations.new-darwin = mkDarwinSystem { hostname = "new-darwin"; };
```
<!---->
## Modifying Configuration
<!---->
### Add System Feature
1. Add option to `modules/common/default.nix`
<!---->
2. Create module in `modules/nixos/` or `modules/darwin/`
<!---->
3. Enable in host's `configuration.nix`
<!---->
### Add User Package
Edit `home-manager/common/packages/default.nix` with platform conditionals.
<!---->
### Modify Shell Aliases
Edit `home-manager/common/shell.nix` for cross-platform zsh aliases.
<!---->
## Development Environments
<!---->
```bash
init-dev-env          # General development
init-latex-env        # LaTeX
init-geant4-env       # Geant4 physics simulation
init-analysis-env     # Data analysis tools, semi-deprecated
```
<!---->
## Roadmap
- [x] Move geant4 development environment into its own repo as a flake
- [x] Unified cross-platform architecture for NixOS and Darwin
- [x] Standardize on zsh across all platforms
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [ ] Expose nixvim configuration as a runnable package (`nix run`)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer)
