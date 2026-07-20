{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.asahi.enable = true;
  # The Asahi installer places peripheral firmware (Wi-Fi, webcam, ALS) at
  # /boot/vendorfw/firmware.cpio. Until the machine is provisioned and that
  # file exists, disable extraction so the config evaluates on the build
  # host. Re-enable (the default) once /boot/vendorfw is present.
  hardware.asahi.extractPeripheralFirmware = false;
}
