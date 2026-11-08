{
  config,
  lib,
  osConfig,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
  # The ultrawide (Sceptre O34) is sometimes probed as DP-5, DP-3, or DP-1.
  # Match by make/model/serial so this works no matter the connector name.
  primaryMonitor =
    if deviceType == "desktop" then "Sceptre Tech Inc Sceptre O34 Unknown" else "eDP-1";
  secondaryMonitor =
    if deviceType == "desktop" then
      "Sceptre Tech Inc Sceptre F22 0x01010101"
    else
      (if deviceType == "laptop" then "HDMI-A-2" else "DP-5");
  alt-proportion = if deviceType == "desktop" then 0.5 else 0.75;

  # Takes an ssh host and runs nvtop there, reconnecting every 5 s while ssh itself
  # fails (exit 255: the host or the bastion is not up yet at login, or the link
  # dropped). Any other exit (quitting nvtop) returns and closes the window.
  remoteNvtop = pkgs.writeShellScript "remote-nvtop" ''
    while :; do
      ssh -t "$1" nvtop
      [ $? -eq 255 ] || exit
      sleep 5
    done
  '';

  # Opens btop, nvtop on son-of-anton, and nvtop on fiona on c-sysmon (the
  # vertical panel), top to bottom, with btop taller. The stacking is niri-tile-to-n's:
  # it consumes each new window on that panel into the column to its left. The
  # script waits for each window to join btop's column before opening the next, so
  # the order holds. If the tiler is not running, the windows stay in separate
  # columns and btop keeps its height.
  sysmonLayout = pkgs.writeShellScript "sysmon-layout" ''
    niri() { ${osConfig.programs.niri.package}/bin/niri "$@"; }
    jq() { ${pkgs.jq}/bin/jq "$@"; }
    # Prints the id of the first window with app-id $1; waits up to 30 s.
    window_id() {
      for _ in $(seq 150); do
        id=$(niri msg --json windows | jq -r --arg app "$1" 'first(.[] | select(.app_id == $app) | .id) // empty')
        if [ -n "$id" ]; then
          echo "$id"
          return 0
        fi
        sleep 0.2
      done
      return 1
    }
    # Succeeds once windows $1 and $2 share a column; gives up after 10 s.
    await_stacked() {
      for _ in $(seq 50); do
        stacked=$(niri msg --json windows | jq --argjson a "$1" --argjson b "$2" \
          '[.[] | select(.id == $a or .id == $b) | .layout.pos_in_scrolling_layout[0]] | length == 2 and (unique | length == 1)')
        [ "$stacked" = true ] && return 0
        sleep 0.2
      done
      return 1
    }
    ${pkgs.kitty}/bin/kitty --class sysmon-btop btop &
    btop=$(window_id sysmon-btop) || exit 1
    ${pkgs.kitty}/bin/kitty --class sysmon-son-of-anton ${remoteNvtop} son-of-anton &
    soa=$(window_id sysmon-son-of-anton) || exit 1
    await_stacked "$soa" "$btop"
    ${pkgs.kitty}/bin/kitty --class sysmon-fiona ${remoteNvtop} fiona &
    fiona=$(window_id sysmon-fiona) || exit 1
    await_stacked "$fiona" "$btop" && niri msg action set-window-height --id "$btop" 48%
  '';

  sysmonDesktop = {
    workspace = [
      {
        _args = [ "c-sysmon" ];
        open-on-output = "Sceptre Tech Inc Sceptre F22 Unknown";
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "^sysmon-";
        };
        open-on-workspace = "c-sysmon";
      }
    ];
    spawn-sh-at-startup = [ [ "sleep 5 && ${sysmonLayout}" ] ];
  };

  workConfigBase = {
    workspace = [
      {
        _args = [ "a-chat" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "slack";
        };
        open-on-workspace = "a-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "thunderbird";
        };
        open-on-workspace = "a-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "Spotify";
        };
        default-column-width = {
          proportion = 1.0;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.thunderbird}/bin/thunderbird && niri msg action move-column-left" ]
      [ "sleep 10 && ${pkgs.slack}/bin/slack && niri msg action move-column-right" ]
    ];

  };

  workConfigDesktopAdditions = {
    debug = {
      render-drm-device = "/dev/dri/igpu-render";
    };
    workspace = [
      {
        _args = [ "b-aux" ];
        open-on-output = secondaryMonitor;
      }
    ]
    ++ sysmonDesktop.workspace;
    window-rule = [
      {
        match._props = {
          app-id = "Spotify";
        };
        open-on-workspace = "b-aux";
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "b-aux";
      }
    ]
    ++ sysmonDesktop.window-rule;
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.spotify}/bin/spotify" ]
    ]
    ++ sysmonDesktop.spawn-sh-at-startup;
  };

  playConfigBase = {
    workspace = [
      {
        _args = [ "b-aux" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "signal";
        };
        open-on-workspace = "b-aux";
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.signal-desktop}/bin/signal-desktop --use-tray-icon" ]
    ];
  };

  playConfigDesktopAdditions = {
    debug = {
      render-drm-device = "/dev/dri/igpu-render";
    };
    workspace = [
      {
        _args = [ "a-media" ];
        open-on-output = primaryMonitor;
      }
    ]
    ++ sysmonDesktop.workspace;
    window-rule = [
      {
        match._props = {
          app-id = "steam";
        };
        open-on-workspace = "a-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "Spotify";
        };
        open-on-workspace = "a-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "a-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
    ]
    ++ sysmonDesktop.window-rule;
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.spotify}/bin/spotify && niri msg action move-column-right" ]
    ]
    ++ sysmonDesktop.spawn-sh-at-startup;
  };

  playConfig =
    if deviceType == "desktop" then
      {
        debug = playConfigDesktopAdditions.debug;
        workspace = playConfigBase.workspace ++ playConfigDesktopAdditions.workspace;
        window-rule = playConfigBase.window-rule ++ playConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          playConfigBase.spawn-sh-at-startup ++ playConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      playConfigBase;

  workConfig =
    if deviceType == "desktop" then
      {
        debug = workConfigDesktopAdditions.debug;
        workspace = workConfigBase.workspace ++ workConfigDesktopAdditions.workspace;
        window-rule = workConfigBase.window-rule ++ workConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          workConfigBase.spawn-sh-at-startup ++ workConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      workConfigBase;
in
{
  config = mkIf (osConfig.systemOptions.owner.e.enable) (mkMerge [
    {
      xdg.configFile."niri/profile.kdl".text =
        if config.Profile == "work" then
          mkNiriKDL workConfig
        else if config.Profile == "play" then
          mkNiriKDL playConfig
        else
          "";
    }
  ]);
}
