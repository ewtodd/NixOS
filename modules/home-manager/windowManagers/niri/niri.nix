{ config, lib, osConfig, pkgs, inputs, ... }:
with lib;
let
  colors = config.colorScheme.palette;
  deviceType = osConfig.DeviceType;
  radius = toString osConfig.CornerRadius;
  wallpaperPath = config.WallpaperPath;
  open-nix-docs = pkgs.writeShellScript "open-nix-docs" ''
    ${pkgs.firefox}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ &
  '';
  notificationColor =
    if (colors.base08 != colors.base0E) then colors.base08 else "F84F31";
  unstable = import inputs.unstable { system = "x86_64-linux"; };
in {

  imports = [
    ./services/misc.nix
    ./services/swayidle.nix
    ./services/swaync.nix
    ./services/swaylock.nix
    ./services/wlogout.nix
    ./services/avizo.nix
    ./launcher/rofi.nix
    ./settings/profile.nix
  ] ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
    ++ optionals (deviceType == "desktop") [ ./settings/desktop.nix ];

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout ""
                model ""
                rules ""
                variant ""
            }
            repeat-delay 600
            repeat-rate 25
            track-layout "global"
        }
        touchpad {
            dwt
            tap
            natural-scroll
        }
        mouse { natural-scroll; }
        focus-follows-mouse
        disable-power-key-handling
    }
    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
    prefer-no-csd
    overview { workspace-shadow { color "#${colors.base00}99"; }; }
    layout {
        gaps 12
        struts {
            left 0
            right 0
            top 0
            bottom 0
        }
        focus-ring {
            width 3
            active-gradient angle=180 from="#${colors.base0D}" relative-to="window" to="#${colors.base0E}"
        }
        border { off; }
        background-color "transparent"
        default-column-width { proportion 0.500000; }
        preset-column-widths {
            proportion 0.250000
            proportion 0.500000
            proportion 0.750000
        }
        preset-window-heights {
            proportion 0.500000
            proportion 1.000000
        }
        center-focused-column "on-overflow"
        always-center-single-column
        empty-workspace-above-first
    }
    hotkey-overlay { skip-at-startup; }
    binds {
        Alt+Ctrl+3 { spawn-sh "grimshot --notify copy output"; }
        Alt+Ctrl+4 { spawn-sh "grimshot --notify copy area"; }
        Alt+Ctrl+Shift+3 { spawn-sh "grimshot --notify save output"; }
        Alt+Ctrl+Shift+4 { spawn-sh "grimshot --notify save area"; }
        Alt+l { spawn "${pkgs.swaylock-effects}/bin/swaylock"; }
        F7 { spawn "lightctl" "down"; }
        F8 { spawn "lightctl" "up"; }
        Mod+1 { focus-monitor-next; }
        Mod+2 { spawn-sh "pkill -USR1 waybar && niri msg action do-screen-transition --delay-ms 0"; }
        Mod+Ctrl+f { toggle-windowed-fullscreen; }
        Mod+Ctrl+r { switch-preset-window-height; }
        Mod+Return { spawn "${pkgs.kitty}/bin/kitty"; }
        Mod+Shift+1 { move-window-to-monitor-next; }
        Mod+Shift+Return { spawn "${pkgs.kitty}/bin/kitty" "--class" "'floatingkitty'"; }
        Mod+Shift+Space { center-window; }
        Mod+Shift+c { spawn "sh" "-c" "pkill -USR2 waybar"; }
        Mod+Shift+d { spawn "${pkgs.rofi}/bin/rofi" "-show" "filebrowser" "-matching" "fuzzy" "-filebrowser-directory" "~"; }
        Mod+Shift+e { spawn "${pkgs.swaynotificationcenter}/bin/swaync-client" "--close-all"; }
        Mod+Shift+f { fullscreen-window; }
        Mod+Shift+g { spawn "${pkgs.firefox}/bin/firefox" "--private-window" "https://looptube.io/?videoId=eaPT0dQgS9E&start=0&end=4111&rate=1"; }
        Mod+Shift+h { move-column-left-or-to-monitor-left; }
        Mod+Shift+j { move-window-down-or-to-workspace-down; }
        Mod+Shift+k { move-window-up-or-to-workspace-up; }
        Mod+Shift+l { move-column-right-or-to-monitor-right; }
        Mod+Shift+n { spawn "${pkgs.swaynotificationcenter}/bin/swaync-client" "-t"; }
        Mod+Shift+p { spawn "${pkgs.firefox}/bin/firefox" "--private-window"; }
        Mod+Shift+q { close-window; }
        Mod+Shift+r { set-column-width "100%"; }
        Mod+Shift+a { move-window-to-workspace-up; }
        Mod+Shift+s { move-window-to-workspace-down; }
        Mod+Shift+t { spawn "firefox" "--new-window" "https://monkeytype.com"; }
        Mod+Shift+w { center-visible-columns; }
        Mod+Space { toggle-window-floating; }
        Mod+Tab { toggle-overview; }
        Mod+a { spawn-sh "${unstable.nirius}/bin/nirius toggle-follow-mode"; }
        Mod+s { spawn-sh "${unstable.nirius}/bin/nirius scratchpad-show"; }
        Mod+Ctrl+s { spawn-sh "${unstable.nirius}/bin/nirius scratchpad-toggle --no-move"; }
        Mod+c { consume-or-expel-window-left; }
        Mod+d { spawn "${pkgs.rofi}/bin/rofi" "-show" "combi" "-modes" "combi" "-combi-modes" "window,drun"; }
        Mod+e { expand-column-to-available-width; }
        Mod+f { spawn "${pkgs.firefox}/bin/firefox"; }
        Mod+h { focus-column-or-monitor-left; }
        Mod+j { focus-window-or-workspace-down; }
        Mod+k { focus-window-or-workspace-up; }
        Mod+l { focus-column-or-monitor-right; }
        Mod+m { spawn "${pkgs.wlogout}/bin/wlogout" "-p" "layer-shell" "--buttons-per-row" "2"; }
        Mod+n { spawn "${pkgs.firefox}/bin/firefox" "-new-window" "https://nix-community.github.io/nixvim/25.05/"; }
        Mod+p { spawn "${open-nix-docs}"; }
        Mod+r { switch-preset-column-width-back; }
        Mod+t { switch-focus-between-floating-and-tiling; }
        Mod+v { consume-or-expel-window-right; }
        Mod+w { center-column; }
        XF86AudioLowerVolume { spawn "volumectl" "-d" "-p" "down"; }
        XF86AudioMute { spawn "volumectl" "-d" "-p" "toggle-mute"; }
        XF86AudioRaiseVolume { spawn "volumectl" "-d" "-p" "up"; }
        XF86MonBrightnessDown { spawn "lightctl" "down"; }
        XF86MonBrightnessUp { spawn "lightctl" "up"; }
    }
    spawn-at-startup "${unstable.nirius}/bin/niriusd"
    spawn-at-startup "waybar"
    spawn-at-startup "swaybg" "-i" "${wallpaperPath}"
    spawn-at-startup "sh" "-c" "sleep 2 && wayland-pipewire-idle-inhibit"
    window-rule {
        geometry-corner-radius ${radius} ${radius} ${radius} ${radius} 
        clip-to-geometry true
    }
    window-rule {
        match is-window-cast-target=true
        border {
            on
            width 3
            active-color "${notificationColor}"
            inactive-color "${notificationColor}"
        }
        focus-ring { off; }
    }
    window-rule {
        match app-id="thunderbird" title="^Write:"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
    }
    window-rule {
        match title="Volume Control"
        default-column-width { proportion 0.300000; }
        default-window-height { proportion 0.600000; }
        open-floating true
    }
    window-rule {
        match app-id="floatingkitty"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
    }
    window-rule {
        match app-id=".blueman-manager-wrapped"
        default-column-width { proportion 0.300000; }
        default-window-height { proportion 0.600000; }
        open-floating true
    }
    window-rule {
        match app-id="udiskie"
        default-column-width { proportion 0.300000; }
        default-window-height { proportion 0.600000; }
        open-floating true
    }
    window-rule {
        match app-id="LISE++"
        default-column-width
        default-window-height
    }
    window-rule {
        match app-id="LISE++"
        exclude title=" L I S E ++   [Noname]"
        open-floating true
    }
    window-rule {
        match app-id="firefox" title="File Upload"
        default-column-width { proportion 0.300000; }
        default-window-height { proportion 0.600000; }
        open-floating true
    }
    window-rule {
        match title="sim"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
    }
    window-rule {
        match title="ROOT"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
    }
    window-rule {
        match app-id="gnome-disks"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
    }
    window-rule {
        match app-id="com.obsproject.Studio"
        default-column-width
        default-window-height
    }
    window-rule {
        match title="Resident Evil 4"
        variable-refresh-rate true
    }
    layer-rule {
        match namespace="swaync-notification-window"
        block-out-from "screen-capture"
    }
    layer-rule {
        match namespace="wallpaper"
        place-within-backdrop true
    }
    gestures { hot-corners { off; }; }
    animations { slowdown 0.75; }
    recent-windows {
        open-delay-ms 150

        highlight {
            urgent-color "#${notificationColor}"
            padding 30
            corner-radius ${radius}
        }

        previews {
            max-height 480
            max-scale 0.5
        }

        binds {
            Alt+Tab         { next-window; }
            Alt+Shift+Tab   { previous-window; }
            Alt+grave       { next-window     filter="app-id"; }
            Alt+Shift+grave { previous-window filter="app-id"; }
        }
       }
  '' + lib.optionalString (deviceType == "laptop") ''
    include "laptop.kdl"
  '' + lib.optionalString (deviceType == "desktop") ''
    include "desktop.kdl"
  '' + lib.optionalString
    (lib.strings.hasPrefix "e" osConfig.networking.hostName) ''
      include "profile.kdl" 
    '';
}
