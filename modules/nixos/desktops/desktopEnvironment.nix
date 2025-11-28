{ pkgs, ... }: {

  imports = [ ./niri/niri-de.nix ];
  services.xserver = {
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
  };
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
    autoSuspend = false;
  };
}
