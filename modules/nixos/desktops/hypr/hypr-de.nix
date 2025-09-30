{ pkgs, config, lib, inputs, ... }:
let unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  config = lib.mkIf (config.WindowManager == "hyprland") {

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
      package = unstable.hyprland;
    };
    programs.uwsm = {
      enable = true;
      waylandCompositors.hyprland = {
        prettyName = "Hyprland";
        comment = "Hyprland compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/Hyprland";
      };
    };

    environment.systemPackages = with pkgs; [
      wlogout
      birdtray
      wl-clipboard
      lxqt.pavucontrol-qt
      pulseaudio
      gthumb
      nautilus
      thunderbird-latest
      udiskie
      glib
      gnome-themes-extra
      brightnessctl
      playerctl
    ];

    environment.shellAliases = { view-image = "kitten icat"; };

    security.pam.services.hyprlock = { };
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
