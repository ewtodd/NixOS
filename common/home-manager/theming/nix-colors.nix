{ config, lib, inputs, ... }:

let profile = config.Profile;
in {
  config = {
    # Set the colorScheme based on profile
    colorScheme = if profile == "work" then
      inputs.nix-colors.colorSchemes.eris
    else
      inputs.nix-colors.colorSchemes.rose-pine;
  };
}
