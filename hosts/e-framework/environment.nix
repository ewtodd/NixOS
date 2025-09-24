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
    "xe.force_probe=46a6"
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

  systemd.services.mod-pre-sleep = {
    description = "Remove wake-causing modules before hibernate";
    wantedBy = [ "hibernate.target" ];
    before = [ "hibernate.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod pkgs.util-linux ];
    script = ''
      # Remove Chrome EC modules (Framework-specific)
      rmmod cros_ec_lpcs 2>/dev/null || true
      rmmod cros_ec_dev 2>/dev/null || true  
      rmmod cros_ec 2>/dev/null || true

      # Remove HID modules  
      rmmod intel_hid 2>/dev/null || true
      rmmod i8042 2>/dev/null || true

      # Store what we removed
      echo "i8042 intel_hid cros_ec cros_ec_dev cros_ec_lpcs" > /tmp/hibernation-modules
    '';
  };

  systemd.services.mod-resume = {
    description = "Restore modules after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      # Reload modules in proper order
      if [ -f /tmp/hibernation-modules ]; then
        for module in $(cat /tmp/hibernation-modules); do
          modprobe "$module" 2>/dev/null || true
        done
        rm -f /tmp/hibernation-modules
      fi
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
    [ "mei_hdcp" "mei_pxp" "mei" "cros_kbd_led_backlight" "i915" ];

  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
