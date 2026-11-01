{
  pkgs,
  lib,
  config,
  ...
}:
{
  config =
    lib.mkIf
      (config.systemOptions.deviceType.desktop.enable || config.systemOptions.deviceType.laptop.enable)
      {
        services.displayManager.noctalia-greeter = {
          enable = true;
          passwordlessSyncUsers = builtins.attrNames (
            lib.filterAttrs (_: user: user.isNormalUser) config.users.users
          );
        };

        programs.niri = {
          enable = true;
        };

        environment.systemPackages = with pkgs; [
          xwayland-satellite
          libnotify
          pix
          nautilus
          file-roller
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
      };
}
