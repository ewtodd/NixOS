{ pkgs, ... }: {
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
        timeout = 660;
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
