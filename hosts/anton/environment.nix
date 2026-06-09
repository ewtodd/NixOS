{
  pkgs,
  ...
}:
{
  # Deliberately NOT pkgs.linuxPackages_latest (as mu/nu use): ZFS lags the
  # newest mainline kernel, so forcing latest can make the box fail to build.
  # We use the nixpkgs default kernel, which is kept ZFS-compatible.
  hardware.firmware = [ pkgs.linux-firmware ];

  # ZFS support for the future data pool. hostId lives in configuration.nix.
  # No pool/datasets defined yet — drives aren't finalized. Root stays ext4.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 5;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
}
