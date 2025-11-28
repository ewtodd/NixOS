{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {
  environment.systemPackages = with unstable; [ i2c-tools ];
  services.hardware.openrgb = {
    enable = true;
    motherboard = "intel";
    package = unstable.openrgb-with-all-plugins;
  };
  services.udev = {
    extraRules = ''
        # OpenRGB rules
      SUBSYSTEM=="usb", ATTR{idVendor}=="1b1c", ATTR{idProduct}=="*", TAG+="uaccess"
      SUBSYSTEM=="usb", ATTR{idVendor}=="2516", ATTR{idProduct}=="*", TAG+="uaccess"
      KERNEL=="i2c-[0-9]*", TAG+="uaccess", GROUP="i2c"
      # PCI permissions for Intel SMBus
      SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x7a23", MODE="0666"
    '';
  };
  boot.kernelParams = [
    "intel_i2c_ioapic_scan=force" # Bypass broken ACPI tables
    "i2c_i801.probe=force" # Override BIOS detection issues
  ];
  boot.kernelModules = [ "i2c-dev" "i2c-i801" ];
  boot.blacklistedKernelModules = [ "spd5118" ];
  hardware.i2c.enable = true;
}
