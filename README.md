# NixOS & nix-darwin Multi-Host Configuration

This repository manages both **NixOS** (Linux) and **nix-darwin** (macOS) systems with a unified, cross-platform configuration structure. The architecture maximizes code reuse while keeping platform-specific concerns isolated.

## Quick Start

```bash
# NixOS: Rebuild and switch
nrs  # Alias for: nh os switch /etc/nixos

# Darwin: Rebuild and switch
nrs  # Alias for: nh darwin switch /etc/nixos

# Update flake inputs
nix flake update

# Fix git permissions
fix-nixos-git
```

## Architecture Overview

The configuration is organized into three main layers:

1. **modules/** - System-level configuration (common, nixos, darwin)
2. **home-manager/** - User-level configuration (common, nixos, darwin)
3. **hosts/** - Per-host specific configuration

```
/etc/nixos/
├── flake.nix                           # Main entry point with mkNixSystem & mkDarwinSystem helpers
├── modules/
│   ├── common/default.nix              # Cross-platform systemOptions definitions
│   ├── nixos/                          # NixOS: desktop env, hardware, security, services
│   └── darwin/                         # macOS: homebrew, system defaults
├── home-manager/
│   ├── common/                         # Cross-platform: packages, shell (zsh), profiles
│   │   ├── profiles/{work,play}.nix    # Unified profiles that auto-import platform modules
│   │   ├── packages/                   # nixvim, git, kitty, fastfetch, etc.
│   │   └── shell.nix                   # zsh + starship configuration
│   ├── nixos/                          # NixOS: niri, DMS, theming, XDG
│   └── darwin/                         # macOS: amethyst, karabiner
└── hosts/{hostname}/
    ├── configuration.nix               # Host system config (enables systemOptions)
    ├── hardware-configuration.nix      # NixOS only
    └── home.nix                        # User definitions (imports profiles)
```

## Key Design Patterns

### 1. Unified `systemOptions`
All hosts have access to `systemOptions` defined in `modules/common/default.nix`:

```nix
systemOptions = {
  owner.e.enable = true;                # Owner identification (cross-platform)
  deviceType.laptop.enable = true;      # Device type (cross-platform)
  services.ai.enable = true;            # AI services (cross-platform)
  graphics.amd.enable = true;           # NixOS-specific (ignored on Darwin)
};
```

### 2. No Conditional Imports Philosophy

**Critical Design Principle**: This configuration **never uses conditional imports**. All modules are imported unconditionally, and platform-specific behavior is controlled via `lib.mkIf` guards inside the modules.

```nix
# ✅ CORRECT: Unconditional imports with mkIf guards
{ lib, pkgs, ... }:
{
  imports = [ ./darwin ./nixos ];  # Always imported

  programs.zathura = lib.mkIf pkgs.stdenv.isLinux {  # Only enabled on Linux
    enable = true;
  };
}

# ❌ WRONG: Conditional imports cause infinite recursion
{ lib, pkgs, ... }:
{
  imports = lib.optionals pkgs.stdenv.isLinux [ ./nixos ];  # DON'T DO THIS
}
```

This prevents infinite recursion issues where `pkgs` depends on `config`, which depends on `imports`.

### 3. Profile System
Users are organized into **work** or **play** profiles that import all platform modules unconditionally:

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

Each platform module uses `mkIf pkgs.stdenv.isLinux` or `mkIf pkgs.stdenv.isDarwin` internally to control activation.

### 3. Platform Detection
Modules use `pkgs.stdenv.isLinux` / `isDarwin` with `mkIf` for conditional activation:

```nix
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  home.packages = lib.optionals isLinux [ signal-desktop ]
               ++ lib.optionals isDarwin [ /* macOS packages */ ];

  programs.dank-material-shell = lib.mkIf isLinux {
    enable = true;
    # ... NixOS-only configuration
  };
}
```

### 4. Safe `osConfig` Access
Home-manager modules safely access system options:

```nix
{ osConfig ? null, ... }:
let
  hasAI = if osConfig != null
    then osConfig.systemOptions.services.ai.enable
    else false;
in { /* ... */ }
```

## Desktop Environments

### NixOS
- **Compositor:** niri (scrollable tiling Wayland)
- **Shell:** DankMaterialShell (DMS)
- **Greeter:** DMS greeter
- **Config:** `home-manager/nixos/desktopEnvironment/`

### Darwin
- **Window Manager:** Amethyst (tiling)
- **Keyboard:** Karabiner-Elements
- **Config:** `home-manager/darwin/`

## Shell & Terminal

- **Shell:** zsh (all platforms)
- **Prompt:** Starship
- **Terminal:** Kitty
- **Editor:** Neovim (nixvim)

Configuration unified in `home-manager/common/shell.nix`.

## Profiles: Work vs Play

- **Work:** clang-tools, slack, SRIM, LISE++, VPN aliases (e-owner), research tools
- **Play:** signal-desktop, mangohud, android-tools, mumble, gaming tools

Set per-user in `hosts/{hostname}/home.nix` via profile import.

## Theming

Colors managed via **nix-colors**. Common schemes:
- Work: `kanagawa`, `atelier-cave`
- Play: `eris`, `harmonic16-dark`

```nix
colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
```

## Adding a New Host

### NixOS
```bash
nixos-generate-config --show-hardware-config > hosts/new-host/hardware-configuration.nix
```

Create `hosts/new-host/configuration.nix` with systemOptions, then add to flake.nix:
```nix
nixosConfigurations.new-host = mkNixSystem { hostname = "new-host"; };
```

### Darwin
Create `hosts/new-darwin/configuration.nix`, then add to flake.nix:
```nix
darwinConfigurations.new-darwin = mkDarwinSystem { hostname = "new-darwin"; };
```

## Modifying Configuration

### Add System Feature
1. Add option to `modules/common/default.nix`
2. Create module in `modules/nixos/` or `modules/darwin/`
3. Enable in host's `configuration.nix`

### Add User Package
Edit `home-manager/common/packages/default.nix` with platform conditionals.

### Modify Shell Aliases
Edit `home-manager/common/shell.nix` for cross-platform zsh aliases.

## Development Environments

```bash
init-dev-env          # General development
init-latex-env        # LaTeX
init-geant4-env       # Geant4 physics simulation
init-analysis-env     # Data analysis tools
```

## Git Workflow

This repo lives in `/etc/nixos` (root-owned):

```bash
fix-nixos-git
git add .
git commit -m "Update configuration"
```

## Flake Inputs

- **nixpkgs** (25.11), **unstable**, **home-manager**, **nix-darwin**
- **nixvim**, **nix-colors**, **niri-nix**, **dank-material-shell**
- **lanzaboote** (secure boot), **nix-homebrew** (Darwin)
- Custom: SRIM, LISE++, reMarkable tools

## Notes

- **Generations:** Old configs remain bootable. Clean with `nh clean`.
- **Caps Lock → Esc:** NixOS-wide via interception-tools.
- **Work/Play:** Separate user accounts with different themes/packages.
- **Darwin Homebrew:** Declaratively managed via nix-homebrew.

## Roadmap
- [x] Move geant4 development environment into its own repo as a flake
- [x] Unified cross-platform architecture for NixOS and Darwin
- [x] Standardize on zsh across all platforms
- [ ] Create proper headless compositor sessions for remote access (Sunshine/Moonlight)
- [ ] Expose nixvim configuration as a runnable package (`nix run`)
- [ ] Add screenshots to README
- [ ] Create live USB system configuration (with Calamares installer) 
