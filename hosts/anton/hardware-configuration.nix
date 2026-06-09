# ============================================================================
# PLACEHOLDER — replace during install.
#
# This file is a stand-in so the flake evaluates before anton's first install.
# During the install (see the runbook), run:
#
#     nixos-generate-config --no-filesystems --root /mnt
#
# then copy the GENERATED /mnt/etc/nixos/hardware-configuration.nix over this
# file, `git add` it, and proceed with nixos-install. The real file will pin
# the ext4 root + vfat ESP by UUID and the detected kernel modules.
#
# `--no-filesystems` is used because we mount manually; we then add the
# fileSystems entries below by hand (or let generate-config write them without
# --no-filesystems — either works, just verify the result).
# ============================================================================
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Minimal placeholder so `nix flake check` / evaluation succeeds before the
  # machine exists. These are intentionally inert and WILL be overwritten by
  # the generated config during install — do not rely on them for booting.
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
