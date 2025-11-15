{ pkgs, osConfig, ... }:
let
  deviceType = osConfig.DeviceType;
  timeout = if (deviceType == "desktop") then 3600 else 660;
in {
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    extraArgs = [ "-w" ];

    timeouts = [
      {
        timeout = 600;
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        timeout = timeout;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];

    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        event = "after-resume";
        command = "${pkgs.swayfx}/bin/swaymsg 'output * power on'";
      }
    ];
  };
}
