{ config, pkgs, lib, osConfig, ... }:

let
  colors = config.colorScheme.palette;
  profile = config.Profile;
  deviceType = osConfig.DeviceType;

  # Font selection based on profile
  fontFamily = if profile == "work" then
    "FiraCode Nerd Font"
  else
    "JetBrains Mono Nerd Font";

  # Monitor configuration
  primaryMonitor = if deviceType == "desktop" then "HDMI-A-3" else "eDP-1";

  # Accent color based on profile
  accentColor = if profile == "work" then colors.base09 else colors.base0E;

in {
  services.mako = {
    enable = true;

    settings = {
      # Default configuration
      "" = {
        # Basic appearance
        background-color = "#${colors.base00}CC"; # Semi-transparent background
        text-color = "#${colors.base05}";
        border-color = "#${accentColor}";
        progress-color = "over #${colors.base02}";

        # Typography
        font = "${fontFamily} 12";

        # Layout and positioning
        width = 400;
        height = 150;
        margin = "10";
        padding = "15";
        border-size = 2;
        border-radius = 8;

        # Behavior
        default-timeout = 8000;
        ignore-timeout = false;
        max-visible = 5;

        # Multi-monitor support - show on secondary monitor when available
        output = primaryMonitor;

        # Grouping
        group-by = "app-name";
        max-icon-size = 48;

        # Actions
        actions = true;

        # Layer and positioning
        layer = "overlay";
        anchor = "top-right";
      };

      # Low urgency notifications
      "urgency=low" = {
        background-color = "#${colors.base01}AA";
        default-timeout = 4000;
      };

      # High urgency notifications
      "urgency=high" = {
        background-color = "#${colors.base08}DD";
        border-color = "#${colors.base08}";
        default-timeout = 12000;
      };

      # Critical urgency notifications
      "urgency=critical" = {
        background-color = "#${colors.base08}";
        border-color = "#${colors.base08}";
        text-color = "#${colors.base00}";
        default-timeout = 0;
      };
    }
    # Profile-specific app styling
      // lib.optionalAttrs (profile == "work") {
        "app-name=Slack" = { border-color = "#${colors.base0B}"; };

        "app-name=Thunderbird" = { border-color = "#${colors.base0D}"; };
      } // lib.optionalAttrs (profile == "play") {
        "app-name=Steam" = { border-color = "#${colors.base0E}"; };

        "app-name=Spotify" = { border-color = "#${colors.base0B}"; };

        "app-name=Signal" = { border-color = "#${colors.base0C}"; };
      };
  };

  # Gaming mode management script
  home.packages = with pkgs; [

    (writeShellScriptBin "audio-check" ''
      #!/bin/bash

      # Check if audio is playing using pipewire/pulseaudio
      if command -v pw-cli >/dev/null 2>&1; then
        # PipeWire check
        audio_playing=$(pw-cli info all | grep -E "state.*running" | grep -v "suspended")
      else
        # PulseAudio fallback
        audio_playing=$(pactl list sink-inputs | grep -E "State: RUNNING")
      fi

      if [[ -n "$audio_playing" ]]; then
        echo "audio_playing"
      else
        echo "audio_idle"
      fi
    '')

    (writeShellScriptBin "mako-waybar" ''
      #!/bin/bash

      # Get notification count
      notification_count=$(makoctl history | jq '.data | length' 2>/dev/null || echo "0")

      # Get current mode - makoctl mode returns the active modes
      mode_output=$(makoctl mode 2>/dev/null || echo "")

      # Check if DND mode is active
      if echo "$mode_output" | grep -q "dnd"; then
        mode="dnd"
      else
        mode="default"
      fi

      # Determine icon and text based on mode and count
      if [[ "$mode" == "dnd" ]]; then
        if [[ "$notification_count" -gt 0 ]]; then
          icon="dnd-notification"
          text="$notification_count (DND)"
        else
          icon="dnd-none"
          text="DND"
        fi
      else
        if [[ "$notification_count" -gt 0 ]]; then
          icon="notification"
          text="$notification_count"
        else
          icon="none"
          text=""
        fi
      fi

      # Get latest notification summary for tooltip
      latest_summary=$(makoctl list | jq -r '.data[0].summary.data // "No notifications"' 2>/dev/null || echo "No notifications")

      # Output JSON for waybar
      printf '{"text":"%s","icon":"%s","tooltip":"%s","class":"%s"}\n' \
        "$text" "$icon" "$latest_summary" "$mode"
    '')
  ];
}
