# NixOS Configuration

This repo contains an opinionated NixOS/home-manager configuration. The desktop environment is composed of niri combined with DankMaterialShell. Theming is controlled via a nix-colors colorScheme option in home-manager. The default behavior is to have two accounts, work and play, with separate themes for proper separation of Church and state. The play account is set up to run Steam and for the most part everything should "just work". The work account contains useful aliases for common data analysis tools used in physics. 

# Roadmap
- [ ] Move mtkclient and lise++ packages to be in independent GitHub repos and using flakes.
- [ ] Create proper headless compositor sessions for accessing desktops remotely via Sunshine/Moonlight. 
