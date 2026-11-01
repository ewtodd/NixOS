{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  e = if osConfig != null then (osConfig.systemOptions.owner.e.enable or false) else false;
  screenshot-fullscreen-clipboard = "noctalia msg screenshot-fullscreen --copy-to-clipboard --no-save-to-file";
  screenshot-region-clipboard = "noctalia msg screenshot-region --copy-to-clipboard --no-save-to-file";
  screenshot-fullscreen-save = "noctalia msg screenshot-fullscreen --save-to-file";
  screenshot-region-save = "noctalia msg screenshot-region --save-to-file";
  lock-screen = "noctalia msg session lock";
  brightness-down = "noctalia msg brightness-down 5";
  brightness-up = "noctalia msg brightness-up 5";
  launcher-toggle = "noctalia msg panel-toggle launcher";
  notification-panel-toggle = "noctalia msg panel-toggle control-center notifications";
  notifications-clear = "noctalia msg notification-clear-active && noctalia msg notification-clear-history";
  powermenu-toggle = "noctalia msg panel-toggle session";
  volume-down = "noctalia msg volume-down 5";
  volume-up = "noctalia msg volume-up 5";
  volume-mute = "noctalia msg volume-mute";
  shell-reload = "noctalia msg config-reload";
  colors = config.scheme;
  deviceType =
    if osConfig != null && (osConfig.systemOptions.deviceType.desktop.enable or false) then
      "desktop"
    else
      "laptop";
  radius = "10";
  open-nix-docs = pkgs.writeShellScript "open-nix-docs-firefox" ''
    ${config.programs.firefox.finalPackage}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ \
      -new-tab -url https://nix-community.github.io/nixvim &
  '';
  phone-home = pkgs.writeShellScriptBin "phone-home" ''
    SOCKET="${config.home.homeDirectory}/.ssh/sockets/mu@ssh.ethanwtodd.com-2222"

    if [ ! -S "$SOCKET" ]; then
      ${pkgs.kitty}/bin/kitty ssh bastion exit
    fi

    setsid ${pkgs.waypipe}/bin/waypipe --remote-node /dev/dri/igpu-render --compress lz4 ssh e-workstation kitty
  '';

  open-fidget-window = pkgs.writeShellScript "open-fidget-window-firefox" "${config.programs.firefox.finalPackage}/bin/firefox --private-window \ https://monkeytype.com";
  open-browser-window = "${config.programs.firefox.finalPackage}/bin/firefox";
  open-private-window = "${config.programs.firefox.finalPackage}/bin/firefox --private-window";
  notificationColor = if (colors.base08 != colors.base0E) then colors.base08 else "F84F31";
  gaps = if e then "12" else "8";
  homeDir = config.home.homeDirectory;
in
{
  imports = [
    ./services.nix
    ./settings/profile.nix
  ]
  ++ lib.optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
  ++ lib.optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  wayland.windowManager.niri = {
    enable = true;
    package = osConfig.programs.niri.package;
    validation.enable = true;
    settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
          repeat-delay = 280;
          repeat-rate = 30;
          track-layout = "global";
        };
        touchpad = {
          dwt = [ ];
          tap = [ ];
          natural-scroll = [ ];
        };
        mouse = {
          natural-scroll = [ ];
        };
        trackpoint = {
          accel-speed = -0.5;
        };
        focus-follows-mouse._props = {
          max-scroll-amount = "15%";
        };
        disable-power-key-handling = [ ];
      };

      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      prefer-no-csd = [ ];

      overview = {
        workspace-shadow = {
          color = "#${colors.base00}99";
        };
      };

      recent-windows = {
        off = [ ];
      };

      layout = {
        gaps = lib.toInt gaps;
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
        focus-ring = {
          off = [ ];
        };
        border = {
          width = 3;
          inactive-color = "#${colors.base03}";
          active-gradient._props = {
            angle = 180;
            from = "#${colors.base0D}";
            relative-to = "window";
            to = "#${colors.base0E}";
          };
        };
        background-color = "transparent";
        default-column-width = {
          proportion = 0.5;
        };
        preset-column-widths._children = [
          { proportion = 0.5; }
          { proportion = 0.75; }
        ];
        preset-window-heights._children = [
          { proportion = 0.5; }
          { proportion = 1.0; }
        ];
        center-focused-column = "on-overflow";
        always-center-single-column = [ ];
        empty-workspace-above-first = [ ];
      };

      hotkey-overlay = {
        skip-at-startup = [ ];
      };

      binds = {
        "Alt+Ctrl+3" = {
          spawn-sh = [ screenshot-fullscreen-clipboard ];
        };
        "Alt+Ctrl+4" = {
          spawn-sh = [ screenshot-region-clipboard ];
        };
        "Alt+Ctrl+Shift+3" = {
          spawn-sh = [ screenshot-fullscreen-save ];
        };
        "Alt+Ctrl+Shift+4" = {
          spawn-sh = [ screenshot-region-save ];
        };
        "Alt+Return" = lib.mkIf (e && deviceType == "laptop") {
          spawn = [ "${phone-home}/bin/phone-home" ];
        };
        "Alt+l" = {
          spawn-sh = [ lock-screen ];
        };
        F7 = {
          spawn-sh = [ brightness-down ];
        };
        F8 = {
          spawn-sh = [ brightness-up ];
        };
        "Mod+1" = {
          focus-monitor-next = [ ];
        };
        "Mod+Ctrl+f" = {
          toggle-windowed-fullscreen = [ ];
        };
        "Mod+Ctrl+r" = {
          switch-preset-window-height = [ ];
        };
        "Mod+Return" = {
          spawn = [ "${pkgs.kitty}/bin/kitty" ];
        };
        "Mod+Shift+1" = {
          move-window-to-monitor-next = [ ];
        };
        "Mod+Shift+Return" = {
          spawn-sh = [
            "${pkgs.kitty}/bin/kitty --class floatingkitty"
          ];
        };
        "Mod+Shift+Space" = {
          center-window = [ ];
        };
        "Mod+Shift+c" = {
          spawn-sh = [ shell-reload ];
        };
        "Mod+Shift+e" = {
          spawn-sh = [ notifications-clear ];
        };
        "Mod+Shift+f" = {
          fullscreen-window = [ ];
        };
        "Mod+Shift+h" = {
          move-column-left-or-to-monitor-left = [ ];
        };
        "Mod+Shift+j" = {
          move-window-down-or-to-workspace-down = [ ];
        };
        "Mod+Shift+k" = {
          move-window-up-or-to-workspace-up = [ ];
        };
        "Mod+Shift+l" = {
          move-column-right-or-to-monitor-right = [ ];
        };
        "Mod+Shift+n" = {
          spawn-sh = [ notification-panel-toggle ];
        };
        "Mod+Shift+p" = {
          spawn-sh = [
            "${open-private-window}"
          ];
        };
        "Mod+Shift+q" = {
          close-window = [ ];
        };
        "Mod+Shift+r" = {
          expand-column-to-available-width = [ ];
        };
        "Mod+Shift+t" = {
          spawn-sh = [
            "${open-fidget-window}"
          ];
        };
        "Mod+Shift+w" = {
          center-visible-columns = [ ];
        };
        "Mod+Shift+z" = {
          spawn-sh = [ "${pkgs.wooz}/bin/wooz" ];
        };
        "Mod+Space" = {
          toggle-window-floating = [ ];
        };
        "Mod+Tab" = {
          toggle-overview = [ ];
        };
        "Mod+c" = {
          consume-or-expel-window-left = [ ];
        };
        "Mod+d" = {
          spawn-sh = [ launcher-toggle ];
        };
        "Mod+f" = {
          spawn-sh = [
            "${open-browser-window}"
          ];
        };
        "Mod+g" = {
          spawn-sh = [ "${pkgs.pix}/bin/pix" ];
        };
        "Mod+h" = {
          focus-column-or-monitor-left = [ ];
        };
        "Mod+j" = {
          focus-window-or-workspace-down = [ ];
        };
        "Mod+k" = {
          focus-window-or-workspace-up = [ ];
        };
        "Mod+l" = {
          focus-column-or-monitor-right = [ ];
        };
        "Mod+m" = {
          spawn = [
            "sh"
            "-c"
            powermenu-toggle
          ];
        };
        "Mod+o" = {
          spawn-sh = [ "${pkgs.kitty}/bin/kitty nvim ${homeDir}/org" ];
        };
        "Mod+p" = {
          spawn = [
            "sh"
            "-c"
            "${open-nix-docs}"
          ];
        };
        "Mod+r" = {
          switch-preset-column-width-back = [ ];
        };
        "Mod+t" = {
          switch-focus-between-floating-and-tiling = [ ];
        };
        "Mod+v" = {
          consume-or-expel-window-right = [ ];
        };
        "Mod+w" = {
          center-column = [ ];
        };
        "Mod+x" = {
          spawn = [ "${pkgs.proton-pass}/bin/proton-pass" ];
        };
        "Mod+z" = {
          spawn = [ "${pkgs.zathura}/bin/zathura" ];
        };
        XF86AudioLowerVolume = {
          spawn = [
            "sh"
            "-c"
            volume-down
          ];
        };
        XF86AudioMute = {
          spawn = [
            "sh"
            "-c"
            volume-mute
          ];
        };
        XF86AudioRaiseVolume = {
          spawn = [
            "sh"
            "-c"
            volume-up
          ];
        };
        XF86MonBrightnessDown = {
          spawn = [
            "sh"
            "-c"
            brightness-down
          ];
        };
        XF86MonBrightnessUp = {
          spawn = [
            "sh"
            "-c"
            brightness-up
          ];
        };
        Page_Up = {
          spawn = [ ];
        };
        Page_Down = {
          spawn = [ ];
        };
      };
      spawn-sh-at-startup = [
        [ "${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme prefer-dark" ]
      ];
      window-rule = [
        {
          geometry-corner-radius = lib.toInt radius;
          clip-to-geometry = true;
        }
        {
          match._props = {
            is-window-cast-target = true;
          };
          border = {
            on = [ ];
            width = 3;
            active-color = "#${notificationColor}";
            inactive-color = "#${notificationColor}";
          };
          focus-ring = {
            off = [ ];
          };
        }
        {
          match._props = {
            app-id = "thunderbird";
            title._raw = ''"^Write:" '';
          };
          default-column-width = {
            proportion = 0.4;
          };
          default-window-height = {
            proportion = 0.7;
          };
          open-floating = true;
        }
        {
          match._props = {
            title = "Volume Control";
          };
          default-column-width = {
            proportion = 0.3;
          };
          default-window-height = {
            proportion = 0.6;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "floatingkitty";
          };
          default-column-width = {
            proportion = 0.4;
          };
          default-window-height = {
            proportion = 0.7;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "udiskie";
          };
          default-column-width = {
            proportion = 0.3;
          };
          default-window-height = {
            proportion = 0.6;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "LISE++";
          };
          default-column-width = [ ];
          default-window-height = [ ];
        }
        {
          match._props = {
            app-id = "LISE++";
          };
          exclude._props = {
            title = " L I S E ++   [Noname]";
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "firefox";
            title = "File Upload";
          };
          default-column-width = {
            proportion = 0.3;
          };
          default-window-height = {
            proportion = 0.6;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "Python3.13";
          };
          default-column-width = {
            proportion = 0.3;
          };
          default-window-height = {
            proportion = 0.6;
          };
          open-floating = true;
        }

        {
          match._props = {
            title = "sim";
          };
          default-column-width = {
            proportion = 0.4;
          };
          default-window-height = {
            proportion = 0.7;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "ROOT";
          };
          default-column-width = {
            proportion = 0.4;
          };
          default-window-height = {
            proportion = 0.7;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "gnome-disks";
          };
          default-column-width = {
            proportion = 0.4;
          };
          default-window-height = {
            proportion = 0.7;
          };
          open-floating = true;
        }
        {
          match._props = {
            app-id = "com.obsproject.Studio";
          };
          default-column-width = [ ];
          default-window-height = [ ];
        }
        {
          match._props = {
            app-id = "Matplotlib";
          };
          open-floating = true;
        }
        {
          match._props = {
            title = ".*Editor$";
          };
          default-column-width = {
            proportion = 0.66667;
          };
          default-window-height = {
            proportion = 1.0;
          };
        }
        {
          match._props = {
            app-id = "^steam_app_";
          };
          variable-refresh-rate = true;
        }
        {
          match._props = {
            title = "Skyrim Special Edition – Mod Organizer v2.5.2";
          };
          variable-refresh-rate = false;
        }
        {
          match._props = {
            app-id = "kitty";
          };
          background-effect = {
            blur = true;
          };
        }
      ];
      layer-rule = [
        {
          match._props = {
            namespace = "noctalia-bar-default";
          };
          background-effect = {
            blur = true;
          };
        }
        {
          match._props = {
            namespace = "^noctalia-notification";
          };
          block-out-from = "screen-capture";
          background-effect = {
            blur = true;
          };
        }
        {
          match._props = {
            namespace = "^noctalia-backdrop";
          };
          place-within-backdrop = true;
        }
      ];
      gestures = {
        hot-corners = {
          top-left = [ ];
        };
      };
      animations = {
        slowdown = 0.75;
      };
      blur = lib.mkIf (!e) {
        passes = 4;
        saturation = 1.8;
      };
    };
    extraConfig = lib.concatStringsSep "\n" (
      [ ]
      ++ lib.optionals (deviceType == "laptop") [ ''include "laptop.kdl"'' ]
      ++ lib.optionals (deviceType == "desktop") [ ''include "desktop.kdl"'' ]
      ++ lib.optionals e [ ''include "profile.kdl"'' ]
    );
  };
}
