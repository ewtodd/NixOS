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
    "mem_sleep_default=s2idle"
    "no_console_suspend"
    "pm_debug_messages"
    "initcall_debug"
    "acpi.ec_no_wakeup=1"
    "pcie_pm_pme=off"
    "nvme_core.default_ps_max_latency_us=0"
    "peci_aspm=off"
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

  # Pre-suspend/hibernate: unload i8042 (equivalent to case pre/* -> rmmod i8042)
  systemd.services.i8042-sleep-pre = {
    description = "Unload i8042 before suspend/hibernate";
    wantedBy = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    before = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    serviceConfig.Type = "oneshot";
    # Ensure rmmod exists at runtime
    path = [ pkgs.kmod ];
    script = ''
      rmmod i8042 || true
    '';
  };

  # Post-resume: reload i8042 with reset=1 (equivalent to case post/* -> modprobe i8042 reset=1)
  # post-resume.target is provided by NixOS for resume hooks
  systemd.services.i8042-resume = {
    description = "Reload i8042 with reset=1 after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      modprobe i8042 reset=1
    '';
  };

  systemd.services.disable-all-wakeups = {
    description = "Disable Framework-specific wakeup sources";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "disable-wakeups" ''
        #!/usr/bin/env bash

        # Framework-specific: Disable Chrome EC wakeups
        if [[ -f /sys/class/chromeos/cros_ec/wakeup ]]; then
          echo disabled > /sys/class/chromeos/cros_ec/wakeup || true
        fi

        # Disable Intel PMC wakeups
        find /sys/devices -path "*/intel_pmc_core*" -name "power/wakeup" 2>/dev/null | while read -r f; do
          echo disabled > "$f" 2>/dev/null || true
        done

        # Standard ACPI wakeup disable
        for dev in $(awk '/*enabled/ {print $1}' /proc/acpi/wakeup); do
          echo "$dev" > /proc/acpi/wakeup || true
        done
      '';
    };
  };

  boot.blacklistedKernelModules =
    [ "mei_hdcp" "mei_pxp" "mei" "cros_kbd_led_backlight" ];

  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
