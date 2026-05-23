{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;
  homeDirectory = if (config.systemOptions.owner.e.enable) then "/home/e-play" else "/home/v-play";

  eDesktopGreeterNiriConfig = mkNiriKDL {
    output = [
      {
        _args = [ "HDMI-A-1" ];
        transform = "270";
        position._props = {
          x = -1080;
          y = 0;
        };
        mode = "1920x1080@74.973";
      }
    ];
    hotkey-overlay = {
      skip-at-startup = [ ];
    };
  };
in
{
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    compositor.customConfig = lib.optionalString config.systemOptions.owner.e.enable eDesktopGreeterNiriConfig;
    configHome = "${homeDirectory}";
    logs.save = true;
  };

  programs.niri = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [
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
