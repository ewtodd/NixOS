{ config, lib, pkgs, ... }: {
  config = lib.mkIf (config.WindowManager == "gnome") {
    services.xserver = {
      enable = true;
      displayManager.startx.enable = false;
      excludePackages = with pkgs; [ xterm ];
      displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = false;
      };
      desktopManager.gnome = { enable = true; };
    };
    environment.gnome.excludePackages = (with pkgs; [
      atomix # puzzle game
      cheese # webcam tool
      epiphany # web browser
      evolution
      gedit # text editor
      gnome-characters
      gnome-music
      gnome-photos
      gnome-terminal
      gnome-tour
      hitori # sudoku game
      iagno # go game
      tali # poker game
      totem # video player
    ]);
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
