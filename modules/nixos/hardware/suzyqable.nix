{ pkgs, ... }:
let
  vboot-ref = pkgs.vboot_reference.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ pkgs.flashrom ];

    makeFlags = builtins.map
      (flag: if flag == "USE_FLASHROM=0" then "USE_FLASHROM=1" else flag)
      oldAttrs.makeFlags;
  });
in {
  environment.systemPackages = with pkgs; [
    openocd
    screen
    vboot-ref
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
