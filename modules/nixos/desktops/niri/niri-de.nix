{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "niri") {
    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
    };
    environment.systemPackages = with pkgs; [
      xwayland-satellite
      wlogout
      birdtray
      wl-clipboard
      swaybg
      jq
      libnotify
      sway-contrib.grimshot
      pavucontrol
      pulseaudio
      gthumb # keep gthumb for detailed image viewing
      imagemagick # for kitty
      nautilus
      thunderbird-latest
      udiskie
      gnome-themes-extra
    ];

    environment.shellAliases = { view-image = "kitten icat"; };

    security.pam.services.swaylock-effects = { };
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    programs.gnome-disks = { enable = true; };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };

    environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };

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

  };
}
