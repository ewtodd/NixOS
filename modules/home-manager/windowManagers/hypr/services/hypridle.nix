{ inputs, pkgs, ... }:
let unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  services.hypridle = {
    enable = true;
    package = unstable.hypridle;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "hyprlock";
        }
        {
          timeout = 660;
          on-timeout = "hyprctl dispatch dpms off && ";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
        }
      ];
    };
  };
}
