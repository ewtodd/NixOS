{ pkgs, ... }: {
  services.swayidle = {
    enable = true;
    package = pkgs.swayidle;
    extraArgs = [ "-w" ];

    timeouts = [
      {
        timeout = 600;
        command = "${pkgs.hyprlock}/bin/hyprlock";
      }
      {
        timeout = 660;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];

    events = [
      {
        event = "before-sleep";
        command = "${pkgs.hyprlock}/bin/hyprlock";
      }
      {
        event = "after-resume";
        command = "${pkgs.swayfx}/bin/swaymsg 'output * power on'";
      }
    ];
  };
}
