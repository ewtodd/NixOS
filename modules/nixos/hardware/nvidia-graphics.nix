{ config, pkgs, inputs, ... }:
let unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  hardware.graphics = {
    enable = true;
    package = unstable.mesa;
  };
  powerManagement.enable = true;
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
    videoDrivers = [ "nvidia" ];
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    package = pkgs.linuxPackages.nvidiaPackages.vulkan_beta;
    open = true;
  };
  boot.extraModprobeConfig = ''
    options nvidia-drm modeset=1
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
    options nvidia NVreg_TemporaryFilePath=/var/tmp
  '';
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];
  systemd.services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS =
    "false";
  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];
}
