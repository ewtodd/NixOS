{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "sway") {

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      extraPackages = with pkgs; [
        wlogout
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
        gsettings-desktop-schemas
      ];
    };

    environment.shellAliases = {
      view-image = "kitten icat";
      get-layer-shells =
        "swaymsg -r -t get_outputs | jq '.[0].layer_shell_surfaces | .[] | .namespace'";
    };

    xdg = {
      portal = {
        enable = true;
        config.common.default = "*";
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
      };
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
      XDG_DATA_DIRS = lib.mkBefore [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };
    programs.ssh.enableAskPassword = false;
  };
}
