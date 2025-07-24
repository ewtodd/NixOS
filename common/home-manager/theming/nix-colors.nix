{ config, lib, inputs, ... }:

let profile = config.Profile;
in {
  config = {
    colorScheme = if profile == "play" then
      inputs.nix-colors.colorSchemes.eris
    else
      inputs.nix-colors.colorSchemes.rose-pine;
  };
}
