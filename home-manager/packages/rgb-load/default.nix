{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  profile = config.Profile;
  enabled =
    (osConfig.systemOptions.hardware.openRGB.enable or false)
    && (profile == "work" || profile == "play");

  mode = if profile == "work" then "cpu" else "gpu";
  description =
    if profile == "work" then
      "OpenRGB load-reactive lighting (CPU)"
    else
      "OpenRGB load-reactive lighting (GPU)";

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.openrgb-python
    ps.nvidia-ml-py
  ]);

  rgb-load = pkgs.writeShellApplication {
    name = "rgb-load";
    runtimeInputs = [ pythonEnv ];
    text = ''
      exec python3 ${./rgb_load.py} "$@"
    '';
  };
in
{
  config = lib.mkIf enabled {
    home.packages = [ rgb-load ];

    systemd.user.services.rgb-load = {
      Unit = {
        Description = description;
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${rgb-load}/bin/rgb-load --mode ${mode}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
