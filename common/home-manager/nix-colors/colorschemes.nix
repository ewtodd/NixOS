{ config, lib, inputs, ... }:

let profile = config.Profile;
in {
  config = {
    # Set the colorScheme based on profile
    colorScheme = if profile == "work" then
      inputs.nix-colors.colorSchemes.catppuccin-latte
    else
      inputs.nix-colors.colorSchemes.dracula;
  };
}
