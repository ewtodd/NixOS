{ pkgs, ... }: {

  imports = [ ./niri/niri-de.nix ];
  services.xserver = {
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
  };
  programs.dankMaterialShell.greeter = {
    enable = true;
    compositor.name = "niri";
    configFiles = [ "/home/e-work/.config/DankMaterialShell/settings.json" ];
  };
}
