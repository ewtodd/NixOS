{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b"
    "snd-intel-dspcfg.dsp_driver=1"
    "mem_sleep_default=s2idle"
    "no_console_suspend"
    "i915.enable_guc=0"
    "i915.max_vfs=0"
    "nvme_core.default_ps_max_latency_us=0"
    "nvme.noacpi=1"
    "pcie_aspm=force"
  ];

  systemd.services.disable-all-wakeups = {
    description = "Disable all ACPI wakeup sources";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-wakeups" ''
        #!/usr/bin/env bash
        # Nuke every single wake source
        for dev in $(${pkgs.gawk}/bin/awk '/\*enabled/ {print $1}' /proc/acpi/wakeup); do
          echo "$dev" > /proc/acpi/wakeup || true
        done
      '';
    };
  };

  boot.blacklistedKernelModules = [
    "snd_sof_pci_intel_tgl"
    "snd_sof_intel_hda_common"
    "snd_sof_intel_hda"
    "snd_sof_pci"
    "snd_sof"
  ];

  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
