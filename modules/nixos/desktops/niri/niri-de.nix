{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "niri") {
    programs.niri = {
      enable = true;
      package = pkgs.niri-stable;
    };
    environment.systemPackages = with pkgs; [
      xwayland-satellite
      wlogout
      cmatrix
      wl-clipboard
      swaybg
      sway-contrib.grimshot
      jq
      libnotify
      pavucontrol
      pulseaudio
      gthumb
      nautilus
      thunderbird-latest
      udiskie
      glib
      gnome-themes-extra
    ];

    xdg.portal = {
      enable = true;
      configPackages = [ pkgs.niri-stable ];
      extraPortals =
        [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
    };

    services.xserver.desktopManager.runXdgAutostartIfNone = true;

    environment.shellAliases = {
      view-image = "kitten icat";
      get-layer-shells =
        "swaymsg -r -t get_outputs | jq '.[0].layer_shell_surfaces | .[] | .namespace'";
    };

    security.pam.services.swaylock-effects = { };
    services.udisks2.enable = true;
    services.gvfs.enable = true;
    programs.dconf.enable = true;
    programs.gnome-disks = { enable = true; };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };
    environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };
    programs.ssh.enableAskPassword = false;
  };
}
