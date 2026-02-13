{
  pkgs,
  lib,
  inputs,
  unstable,
  config,
  ...
}:
let
  niri = inputs.niri.packages."x86_64-linux".default;
  homeDirectory = if (config.systemOptions.owner.e.enable) then "/home/e-play" else "/home/v-play";
in
{
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "${homeDirectory}";
    logs.save = true;
  };
  programs.niri = {
    enable = true;
    package = if (config.systemOptions.apps.niri.blur.enable) then niri else unstable.niri;
  };

  environment.systemPackages = with pkgs; [
    unstable.nirius
    xwayland-satellite
    jq
    libnotify
    gthumb
    nautilus
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
      common = {
        default = [ "gnome" ];
      };
      niri = {
        default = [
          "gtk"
          "gnome"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.Settings" = [ "gnome" ];
      };
    };
  };

  services.udisks2.enable = true;
  services.gvfs.enable = true;
  programs.dconf.enable = true;
  programs.gnome-disks = {
    enable = true;
  };

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
}
