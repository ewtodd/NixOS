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
