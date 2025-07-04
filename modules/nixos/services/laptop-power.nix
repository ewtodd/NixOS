{ config, pkgs, ... }: {
  powerManagement.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 100;
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 95;
      DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth";
    };
  };
}
