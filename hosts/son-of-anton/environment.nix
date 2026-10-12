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

  boot.supportedFilesystems = [ "btrfs" ];

  boot.kernelParams = [
    "amd_pstate=active"
    "iommu=pt"
    "ttm.pages_limit=32505856"
    "ttm.page_pool_size=32505856"
    "pcie_aspm=off"
    # Both R9700s sit behind one PEX88048 switch on a single root port. With ACS redirect on
    # (the kernel enables it whenever an IOMMU driver is loaded, iommu=pt included), card<->card
    # traffic is sent up to the root complex, which does not route it back down the same port:
    # peer reads never complete and the reading queue wedges. Let the switch route peer traffic
    # directly (TP=2 all-reduces, unholy's peer probes).
    "pci=disable_acs_redir=pci:1000:c012"
    # The ASM1166 SATA card reports 32 ports (mask 0xffffff3f) but has 6; when ahci touches the
    # missing ones the controller resets itself (config space back to defaults, every register
    # reads 0xffffffff) and no drive appears. Limit ahci to the six real ports. Applies to every
    # AHCI controller (this is the only one) so bus renumbering can't silently drop it.
    "ahci.mask_port_map=0x3f"
  ];
}
