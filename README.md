# NixOS Configuration

This repo contains an opinionated NixOS/home-manager configuration. The desktop environment is composed of niri or SwayFX combined with many GNOME apps, waybar, swaync, and other common tools. Theming is controlled via a nix-colors colorScheme option in home-manager. The default behavior is to have two accounts, work and play, with separate themes for proper separation of Church and state. The play account is set up to run Steam and for the most part everything should "just work". The work account contains useful aliases for common data analysis tools used in physics. 

# Roadmap
## Short term:
- [ ] Move mtkclient and lise++ packages to be in independent GitHub repos and using flakes.
- [ ] Switch from nix modules, in the sense of chunks of code that you manually decide whether or not to import, to standard NixOS style modules where you enable options within your configuration and the rest is abstracted away. 
- [ ] Create proper headless compositor sessions for accessing desktops remotely via Sunshine/Moonlight. 
## Long term:
- [ ] Convert from nix-colors to base16.nix, since this is actually maintained.
- [ ] ~~Write a new Wayland compositor (possibly a fork of dwl similar to MangoWC) to mimic the functionality of sway with some of the modern conveniences of Niri (per window screen sharing, overview, animations, ...) that is configured entirely via Nix.~~
- [ ] Write a complete Wayland shell to replace the combination of waybar+swaync+avizo that is compositor independent and configured entirely via Nix. 
