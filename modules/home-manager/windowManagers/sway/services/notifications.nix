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
  # Keep your existing script
  home.packages = with pkgs; [
    cosmic-notifications
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
  ];
}
