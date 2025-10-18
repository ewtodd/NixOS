{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "niri") {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
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
      gthumb
      nautilus
      thunderbird-latest
      udiskie
      glib
      gnome-themes-extra
      wayland-pipewire-idle-inhibit
    ];

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        common = { default = [ "gtk" ]; };
        niri = {
          default = [ "gtk" "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
      };
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
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "niri";
    };
    programs.ssh.enableAskPassword = false;
  };
}
