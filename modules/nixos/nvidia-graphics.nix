{ config, pkgs, inputs, ... }:
let
  unstable = import inputs.unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in {
  nixpkgs.config.allowUnfree = true;
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
  };
  powerManagement.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = pkgs.linuxPackages_cachyos.nvidiaPackages.latest;
    nvidiaSettings = true;
    open = true;
  };
  boot.extraModprobeConfig = ''
    options nvidia-drm modeset=1
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS =
    "false";
  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];
}
