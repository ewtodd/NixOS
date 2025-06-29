{ pkgs, config, lib, inputs, ... }: {
  config = lib.mkIf (config.WindowManager == "sway") {

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      extraPackages = with pkgs; [
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
        glib
        gnome-themes-extra
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
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = ''
            ${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format "%c" --user-menu --greeting "Access is restricted to authorized personnel only. NO DOGS!" --cmd sway'';
          user = "greeter";
        };
      };
    };

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

  };
}
