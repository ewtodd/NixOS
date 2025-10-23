{ pkgs, inputs, ... }:
let
  colorScheme = inputs.nix-colors.colorSchemes.grayscale-dark;
  schemeName = colorScheme.slug;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in {

  imports = [ ./sway/sway-de.nix ];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

}
