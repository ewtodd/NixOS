{ pkgs, ... }: {
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    extraArgs = [ "-w" ];

    timeouts = [
      {
        timeout = 600;
        command = "conditional-lock";
      }
      {
        timeout = 660;
        command = "conditional-suspend";
      }
    ];

    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        event = "after-resume";
        command = "${pkgs.sway}/bin/swaymsg 'output * power on'";
      }
    ];
  };
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

    (writeShellScriptBin "conditional-lock" ''
      #!/bin/bash

      # Check audio status
      audio_status=$(audio-check)

      if [[ "$audio_status" == "audio_idle" ]]; then
        ${pkgs.swaylock-effects}/bin/swaylock
      fi
    '')

    (writeShellScriptBin "conditional-suspend" ''
      #!/bin/bash
      audio_status=$(audio-check)

      if [[ "$audio_status" == "audio_idle" ]]; then
        ${pkgs.systemd}/bin/systemctl suspend
      fi
    '')
  ];
}
