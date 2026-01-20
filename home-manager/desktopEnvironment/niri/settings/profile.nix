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

  toggle-signal = pkgs.writeShellScript "toggle-signal" ''
    MONITOR_SOURCE_NAME="alsa_output.pci-0000_03_00.1.hdmi-surround-extra3.monitor"
    monitor_src=$(${pkgs.pulseaudio}/bin/pactl list sources short | grep "$MONITOR_SOURCE_NAME" | awk '{print $1}')
    STATE_FILE="/tmp/electron_pulseaudio_toggle.state"
    toggle_stream() {
      ${pkgs.pulseaudio}/bin/pactl list source-outputs | awk 'BEGIN{RS=""} 
        /application.process.binary = "electron"/ { 
          if (match($0, /Source Output #([0-9]+)/, arr)) idx=arr[1];
          if (match($0, /Source: ([0-9]+)/, arr2)) src=arr2[1];
          print idx, src
        }'
    }
    result=$(toggle_stream)
    so_idx=$(echo "$result" | awk '{print $1}')
    orig_src=$(echo "$result" | awk '{print $2}')

    if [[ -z $so_idx || -z $orig_src ]]; then
      echo "No Electron stream found!"
      exit 1
    fi

    if [[ -f "$STATE_FILE" ]]; then
      last_src=$(cat "$STATE_FILE")
    else
      last_src=$orig_src
    fi

    if [[ "$orig_src" == "$monitor_src" ]]; then
      echo "Switching Electron stream #$so_idx back to $last_src"
      ${pkgs.pulseaudio}/bin/pactl move-source-output "$so_idx" "$last_src"
      rm -f "$STATE_FILE"
    else
      echo "$orig_src" > "$STATE_FILE"
      echo "Switching Electron stream #$so_idx to monitor source #$monitor_src"
      ${pkgs.pulseaudio}/bin/pactl move-source-output "$so_idx" "$monitor_src"
    fi
  '';

  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
  primaryMonitor = if deviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if deviceType == "desktop" then
      "HDMI-A-1"
    else
      (if deviceType == "laptop" then "HDMI-A-2" else "DP-3");
  alt-proportion = if deviceType == "desktop" then 0.5 else 0.75;

  workConfig = {
    workspace = [
      {
        _args = [ "b-chat" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "Slack";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "thunderbird";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "firefox";
        };
        default-column-width = {
          proportion = alt-proportion;
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
      [ "${pkgs.thunderbird-latest}/bin/thunderbird && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.slack}/bin/slack && niri msg action move-column-right" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];
  };

  playConfigBase = {
    workspace = [
      {
        _args = [ "c-chat" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "firefox";
        };
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "signal";
        };
        open-on-workspace = "c-chat";
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.signal-desktop}/bin/signal-desktop --use-tray-icon" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];
    binds = {
      "Mod+o" = {
        spawn = [
          "sh"
          "-c"
          "${toggle-signal}"
        ];
      };
    };
  };

  playConfigDesktopAdditions = {
    workspace = [
      {
        _args = [ "b-media" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "steam";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.spotify}/bin/spotify && niri msg action move-column-right" ]
    ];
  };

  playConfig =
    if deviceType == "desktop" then
      {
        workspace = playConfigBase.workspace ++ playConfigDesktopAdditions.workspace;
        window-rule = playConfigBase.window-rule ++ playConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          playConfigBase.spawn-sh-at-startup ++ playConfigDesktopAdditions.spawn-sh-at-startup;
        binds = playConfigBase.binds;
      }
    else
      playConfigBase;
in
{
  config = mkIf (osConfig.systemOptions.owner.e.enable) {
    xdg.configFile."niri/profile.kdl".text =
      if config.Profile == "work" then
        mkNiriKDL workConfig
      else if config.Profile == "play" then
        mkNiriKDL playConfig
      else
        "";
  };
}
