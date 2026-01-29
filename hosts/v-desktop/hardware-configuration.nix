{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  powerManagement = {
    enable = true;
    powertop.enable = false;
    cpuFreqGovernor = lib.mkForce "performance";
  };

  systemd.services.cpu-performance-bias = {
    description = "Set CPU energy performance bias to performance";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.linuxPackages.cpupower}/bin/cpupower set -b 0
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-intel"
    "amdgpu"
  ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e7e8c9c5-7bc7-4d36-9256-544bad86358d";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-917fb515-b4b7-4788-ad5b-3757f63a792d".device =
    "/dev/disk/by-uuid/917fb515-b4b7-4788-ad5b-3757f63a792d";
  boot.initrd.luks.devices."luks-243582c8-3a2d-4b29-a02e-7f1d06a1862e".device =
    "/dev/disk/by-uuid/243582c8-3a2d-4b29-a02e-7f1d06a1862e";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/90F5-6F70";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/e9b86c6b-7f5a-4335-8bfa-2109472da470"; } ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp3s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
