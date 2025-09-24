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
    "i915.enable_guc=0"
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

  systemd.services.mod-pre-sleep = {
    description = "Unload kernel modules before suspend/hibernate";
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
      rmmod intel_hid
    '';
  };

  systemd.services.mod-resume = {
    description = "Reload kernel modules with reset=1 after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      modprobe intel_hid 
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
