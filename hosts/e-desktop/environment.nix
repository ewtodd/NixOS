{
  lib,
  unstable,
  inputs,
  pkgs,
  ...
}:
{

  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
  hardware.firmware = [ unstable.linux-firmware ];

  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.initrd.luks.devices."luks-0c8c96c9-7128-4635-8958-2e2cead680a0".device =
    "/dev/disk/by-uuid/0c8c96c9-7128-4635-8958-2e2cead680a0";

  boot.resumeDevice = "/dev/disk/by-uuid/7a17f4e4-8dca-427f-9138-340e6b4b778f";
  boot.kernelParams = [
    "resume=0c8c96c9-7128-4635-8958-2e2cead680a0"
  ];

}
