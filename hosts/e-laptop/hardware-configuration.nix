{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages;
    [ v4l2loopback.out ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/602ec4d4-5ce3-4019-a121-1d7a3acda52a";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-5583f8f8-c4b2-4a11-9cce-5db033529ba6".device =
    "/dev/disk/by-uuid/5583f8f8-c4b2-4a11-9cce-5db033529ba6";

  swapDevices =
    [{ device = "/dev/disk/by-uuid/b71761c0-68fa-41ca-9921-fcc6eb207eff"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
