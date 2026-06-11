{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.rgbLoad;

  # GPU utilization source is inferred from the host's graphics stack:
  # nvidia -> NVML (pynvml), amd -> amdgpu sysfs gpu_busy_percent.
  gpu =
    if config.systemOptions.graphics.nvidia.enable then
      "nvidia"
    else if config.systemOptions.graphics.amd.enable then
      "amd"
    else
      "none";

  pythonEnv = pkgs.python3.withPackages (
    ps:
    lib.optional (cfg.backend == "openrgb") ps.openrgb-python
    ++ lib.optional (gpu == "nvidia") ps.nvidia-ml-py
  );

  rgb-load = pkgs.writeShellApplication {
    name = "rgb-load";
    runtimeInputs = [ pythonEnv ] ++ lib.optional (cfg.backend == "framework") pkgs.framework-tool;
    text = ''
      exec python3 ${./rgb_load.py} "$@"
    '';
  };
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.rgb-load = {
      description = "Load-reactive RGB lighting (drives color from max of CPU/GPU utilization)";
      wantedBy = [ "multi-user.target" ];
      # The OpenRGB backend talks to the OpenRGB SDK server (services.hardware.openrgb).
      after = lib.optional (cfg.backend == "openrgb") "openrgb.service";
      wants = lib.optional (cfg.backend == "openrgb") "openrgb.service";
      serviceConfig = {
        ExecStart = "${rgb-load}/bin/rgb-load --backend ${cfg.backend} --gpu ${gpu}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
