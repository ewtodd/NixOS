{ config, lib, osConfig, pkgs, inputs, ... }:
with lib;
let
  e = if (lib.strings.hasPrefix "e" osConfig.networking.hostName) then
    true
  else
    false;
  colors = config.colorScheme.palette;
  deviceType = osConfig.DeviceType;
  radius = toString osConfig.CornerRadius;
  open-nix-docs-firefox = pkgs.writeShellScript "open-nix-docs-firefox" ''
    ${pkgs.firefox}/bin/firefox --new-window \
      -url https://search.nixos.org/packages \
      -new-tab -url https://search.nixos.org/options? \
      -new-tab -url https://home-manager-options.extranix.com/ \
      -new-tab -url https://nix-community.github.io/nixvim/25.11/ &
  '';
  open-nix-docs-qutebrowser =
    pkgs.writeShellScript "open-nix-docs-qutebrowser" ''
      ${pkgs.qutebrowser}/bin/qutebrowser --target private-window https://search.nixos.org/ 
    '';
  open-fidget-window-qutebrowser =
    pkgs.writeShellScript "open-fidget-window-qutebrowser" ''
      ${pkgs.qutebrowser}/bin/qutebrowser --target private-window https://monkeytype.com
    '';
  open-fidget-window-firefox =
    pkgs.writeShellScript "open-fidget-window-qutebrowser" ''
        ${pkgs.firefox}/bin/firefox --new-window \
      -url https://monkeytype.com 
    '';
  open-nix-docs =
    if e then open-nix-docs-qutebrowser else open-nix-docs-firefox;
  open-fidget-window =
    if e then open-fidget-window-qutebrowser else open-fidget-window-firefox;
  open-browser-window = if e then
    "${pkgs.qutebrowser}/bin/qutebrowser --target window"
  else
    "${pkgs.firefox}/bin/firefox";

  open-private-window = if e then
    "${pkgs.qutebrowser}/bin/qutebrowser --target private-window"
  else
    "${pkgs.firefox}/bin/firefox --private-window";
  notificationColor =
    if (colors.base08 != colors.base0E) then colors.base08 else "F84F31";
  unstable = import inputs.unstable { system = "x86_64-linux"; };
in {

  imports = [ ./services.nix ./settings/profile.nix ]
    ++ optionals (deviceType == "laptop") [ ./settings/laptop.nix ]
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
        focus-follows-mouse max-scroll-amount="15%"
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
        Alt+Ctrl+3 { spawn-sh "dms screenshot full --no-notify --no-file"; }
        Alt+Ctrl+4 { spawn-sh "dms screenshot --no-notify --no-file"; }
        Alt+Ctrl+Shift+3 { spawn-sh "dms screenshot full"; }
        Alt+Ctrl+Shift+4 { spawn-sh "dms screenshot"; }
        Alt+l { spawn-sh "dms ipc lock lock"; }
        F7 { spawn-sh "dms ipc brightness decrement 5 \"\" "; }
        F8 { spawn-sh "dms ipc brightness increment 5 \"\" "; }
        Mod+1 { focus-monitor-next; }
        Mod+2 { spawn-sh "pkill -USR1 waybar && niri msg action do-screen-transition --delay-ms 0"; }
        Mod+Ctrl+f { toggle-windowed-fullscreen; }
        Mod+Ctrl+r { switch-preset-window-height; }
        Mod+Return { spawn "${pkgs.kitty}/bin/kitty"; }
        Mod+Shift+1 { move-window-to-monitor-next; }
        Mod+Shift+Return { spawn "${pkgs.kitty}/bin/kitty" "--class" "'floatingkitty'"; }
        Mod+Shift+Space { center-window; }
        Mod+Shift+c { spawn-sh "systemctl --user restart dms.service"; }
        Mod+Shift+e { spawn-sh "dms ipc call notifications clearAll"; } 
        Mod+Shift+f { fullscreen-window; }
        Mod+Shift+h { move-column-left-or-to-monitor-left; }
        Mod+Shift+j { move-window-down-or-to-workspace-down; }
        Mod+Shift+k { move-window-up-or-to-workspace-up; }
        Mod+Shift+l { move-column-right-or-to-monitor-right; }
        Mod+Shift+n { spawn-sh "dms ipc notifications toggle"; }
        Mod+Shift+p { spawn-sh "${open-private-window}"; }
        Mod+Shift+q { close-window; }
        Mod+Shift+r { set-column-width "100%"; }
        Mod+Shift+a { move-window-to-workspace-up; }
        Mod+Shift+s { move-window-to-workspace-down; }
        Mod+Shift+t { spawn-sh "${open-fidget-window}"; }
        Mod+Shift+w { center-visible-columns; }
        Mod+Space { toggle-window-floating; }
        Mod+Tab { toggle-overview; }
        Mod+a { spawn-sh "${unstable.nirius}/bin/nirius toggle-follow-mode"; }
        Mod+s { spawn-sh "${unstable.nirius}/bin/nirius scratchpad-show"; }
        Mod+Ctrl+s { spawn-sh "${unstable.nirius}/bin/nirius scratchpad-toggle --no-move"; }
        Mod+c { consume-or-expel-window-left; }
        Mod+d { spawn-sh "dms ipc spotlight toggle"; }
        Mod+e { expand-column-to-available-width; }
        Mod+f { spawn-sh "${open-browser-window}"; }
        Mod+h { focus-column-or-monitor-left; }
        Mod+j { focus-window-or-workspace-down; }
        Mod+k { focus-window-or-workspace-up; }
        Mod+l { focus-column-or-monitor-right; }
        Mod+m { spawn-sh "dms ipc powermenu toggle"; }
        Mod+p { spawn "${open-nix-docs}"; }
        Mod+r { switch-preset-column-width-back; }
        Mod+t { switch-focus-between-floating-and-tiling; }
        Mod+v { consume-or-expel-window-right; }
        Mod+x { spawn "${pkgs.proton-pass}/bin/proton-pass"; }
        Mod+z { spawn "${pkgs.zathura}/bin/zathura"; }
        Mod+w { center-column; }
        XF86AudioLowerVolume { spawn-sh "dms ipc audio decrement 5"; }
        XF86AudioMute { spawn-sh "dms ipc audio mute"; }
        XF86AudioRaiseVolume { spawn-sh "dms ipc audio increment 5"; }
        XF86MonBrightnessDown { spawn-sh "dms ipc brightness decrement 5 \"\" "; }
        XF86MonBrightnessUp { spawn-sh "dms ipc brightness increment 5 \"\" "; }
    }
    spawn-at-startup "${unstable.nirius}/bin/niriusd"
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
        match app-id="ROOT"
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
        match title="Settings"
        match app-id="org.quickshell"
        open-floating true
    }
    window-rule {
        match app-id="com.obsproject.Studio"
        default-column-width
        default-window-height
    }
    window-rule {
        match app-id="Proton Pass"
        match title="Proton Pass"
        default-column-width { proportion 0.400000; }
        default-window-height { proportion 0.700000; }
        open-floating true
        block-out-from "screen-capture"
    }
    window-rule {
        match title="Resident Evil 4"
        variable-refresh-rate true
    }
    layer-rule {
        match namespace="dms:notification-popup"
        block-out-from "screen-capture"
    }
    layer-rule {
        match namespace="dms:blurwallpaper"
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
  '' + lib.optionalString e ''
    include "profile.kdl" 
  '';
}
