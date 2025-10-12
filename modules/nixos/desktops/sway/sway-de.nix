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
        pulseaudio
        gthumb
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
    xdg = {
      portal = {
        enable = true;
        wlr.settings = {
          screencast = {
            chooser_type = "dmenu";
            chooser_cmd = "${pkgs.rofi-wayland}/bin/rofi -dmenu";
          };
        };
      };
    };
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    programs.ssh.enableAskPassword = false;
  };
}
