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
        command = "dms ipc call lock lock";
      }
      {
        timeout = timeout;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];

    events = [{
      event = "before-sleep";
      command = "dms ipc call lock lock";
    }];
  };
}
