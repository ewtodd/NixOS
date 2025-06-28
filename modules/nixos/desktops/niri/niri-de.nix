{ pkgs, config, lib, ... }: {
  config = lib.mkIf (config.WindowManager == "niri") {
    programs.niri.enable = true;
    environment.systemPackages = with pkgs; [
      xwayland-satellite
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
      gnome-themes-extra
    ];

    environment.shellAliases = {
      view-image = "kitten icat";
      get-layer-shells =
        "swaymsg -r -t get_outputs | jq '.[0].layer_shell_surfaces | .[] | .namespace'";
    };

    security.pam.services.swaylock-effects = { };
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    qt = {
      enable = true;
      platformTheme = "gtk2";
      style = "gtk2";
    };

    programs.gnome-disks = { enable = true; };

    programs.nautilus-open-any-terminal = {
      enable = true;
      terminal = "kitty";
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      GTK_THEME = "Dracula";
    };

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
            ${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format "%c" --user-menu --greeting "Access is restricted to authorized personnel only. NO DOGS!" --cmd niri'';
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
