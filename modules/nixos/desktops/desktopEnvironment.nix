{ pkgs, inputs, ... }:
let
  colorScheme = inputs.nix-colors.colorSchemes.grayscale-dark;
  schemeName = colorScheme.slug;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in {

  nixpkgs.overlays = [
    (self: super: {
      xdg-desktop-portal-wlr = super.xdg-desktop-portal-wlr.overrideAttrs {
        src = self.fetchFromGitHub {
          owner = "emersion";
          repo = "xdg-desktop-portal-wlr";
          rev = "a08b8516740e325ea14a738652693856cfffa011";
          sha256 = "sha256-0zIRCA1z7df9IU3PouwEJBHiETaJaYj9lwpmE1B1fOU=";
        };
      };
    })
  ];

  imports = [ ./sway/sway-de.nix ./niri/niri-de.nix ];
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
