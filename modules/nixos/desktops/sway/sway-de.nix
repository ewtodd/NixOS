{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "sway") {

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      extraPackages = with pkgs; [
        wlogout
        birdtray
        wl-clipboard
        swaybg
        sway-contrib.grimshot
        jq
        libnotify
        lxqt.pavucontrol-qt
        pulseaudio
        gthumb
        imagemagick # for kitty
        nautilus
        thunderbird-latest
        udiskie
        glib
        gnome-themes-extra
        brightnessctl
      ];
    };
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
    programs.ssh.enableAskPassword = false;
  };
}
