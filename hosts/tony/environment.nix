{
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.loader.timeout = 0;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=false"
    "rd.udev.log_level=3"
  ];
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
  ];

  hardware.enableAllFirmware = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
