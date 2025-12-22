{ pkgs, ... }: {

  imports = [ ./niri/niri-de.nix ];
  services.xserver = {
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
  };
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
  };
}
