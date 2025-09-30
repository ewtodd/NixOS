{ pkgs, inputs, ... }:
let
  colorScheme = inputs.nix-colors.colorSchemes.grayscale-dark;
  schemeName = colorScheme.slug;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in {
  imports = [ ./sway/sway-de.nix ./hypr/hypr-de.nix ];
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
    displayManager.gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false;
    };
  };

}
