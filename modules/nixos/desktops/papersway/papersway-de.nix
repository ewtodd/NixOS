{ pkgs, config, lib, inputs, ... }:
let
  papersway = pkgs.perl540Packages.Apppapersway.overrideAttrs (oldAttrs: {
    version = "2.001";
    src = pkgs.fetchurl {
      url =
        "mirror://cpan/authors/id/S/SP/SPWHITTON/App-papersway-2.001.tar.gz";
      hash = "sha256-Jx8MJdyr/tfumMhuCofQX0r3vWcVuDzfJGpCjq2+Odw=";
    };
  });
in {
  config = lib.mkIf (config.WindowManager == "papersway") {

    programs.sway = {
      enable = true;
      package = pkgs.swayfx;
      extraPackages = with pkgs; [
        papersway
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
