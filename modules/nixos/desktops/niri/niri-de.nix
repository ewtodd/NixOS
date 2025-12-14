{ pkgs, config, lib, inputs, ... }:
let
  niri = inputs.niri.packages."x86_64-linux".default;
  unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  config = lib.mkIf (config.WindowManager == "niri") {
    programs.niri = {
      enable = true;
      package = niri;
    };

    environment.systemPackages = with pkgs; [
      unstable.nirius
      xwayland-satellite
      cmatrix
      wl-clipboard
      jq
      libnotify
      gthumb
      nautilus
      thunderbird-latest
      udiskie
      glib
      gnome-themes-extra
    ];

    services.upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common = { default = [ "gnome" ]; };
        niri = {
          default = [ "gtk" "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          "org.freedesktop.impl.portal.Settings" = [ "gnome" ]; # Add this
        };
      };
    };
    environment.shellAliases = { view-image = "kitten icat"; };

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
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      XDG_SESSION_TYPE = "wayland";
      XDG_DATA_DIRS = lib.mkBefore [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };
    programs.ssh.enableAskPassword = false;
  };
}
