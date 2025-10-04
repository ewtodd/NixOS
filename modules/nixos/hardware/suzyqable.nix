{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    openocd
    screen
    usbutils
    libusb1
    flashrom
  ];
  services.udev.extraRules = ''
    # SuzyQable debug cable
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", ATTR{idProduct}=="5014", MODE="0666", GROUP="plugdev"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="5014", MODE="0666", GROUP="dialout"
  '';
}
