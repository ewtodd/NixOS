{ inputs, ... }:
let unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  wayland.windowManager.hyprland.settings.exec-once = [ "hyprsunset" ];
  home.packages = with unstable; [ hyprsunset ];
  home.file.".config/hypr/hyprsunset.conf".text = ''

    profile {
        time = 6:00
        identity = true
    }

    profile {
        time = 21:00
        temperature = 4750 
    }
  '';
}
