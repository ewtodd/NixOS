{ ... }: {
  programs.caelestia = {
    enable = true;
    systemd = {
      enable = false; # if you prefer starting from your compositor
      target = "graphical-session.target";
      environment = [ ];
    };
    settings = {
      bar.status = { showBattery = true; };
      paths.wallpaperDir =
        "/etc/nixos/modules/home-manager/windowManagers/sway/wallpapers";
    };
    cli = {
      enable = true; # Also add caelestia-cli to path
      settings = { theme.enableGtk = false; };
    };
  };
  wayland.windowManager.hyprland = {

    settings = { exec-once = [ "caelestia-shell" ]; };
  };

}
