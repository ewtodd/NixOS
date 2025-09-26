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
    "ec_intr=0"
    "xe.force_probe=46a6"
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

  systemd.services.mod-pre-sleep = {
    description = "Make sure we hibernate in the right mode!";
    wantedBy = [ "hibernate.target" ];
    before = [ "systemd-hibernate.service" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.util-linux ];
    script = ''
      echo "shutdown" > /sys/power/disk
    '';
  };

  #  systemd.services.fix-pre = {
  #    description = "Bluetooth is the last thing blocking me?";
  #    path = [ pkgs.kmod pkgs.bluez ];
  #    wantedBy = [ "suspend.target" "hibernate.target" ];
  #    before = [ "systemd-suspend.service" "systemd-hibernate.service" ];
  #    serviceConfig.Type = "oneshot";
  #    script = ''
  #      rmmod btusb
  #      rmmod atkbd
  #      rmmod cros-ec-keyb
  #      rmmod i2c_hid_acpi
  #      rmmod i2c_hid
  #    '';
  #  };
  #
  #  systemd.services.fix-post = {
  #    description = "Bluetooth is the last thing blocking me?";
  #    path = [ pkgs.kmod pkgs.bluez ];
  #    wantedBy = [ "suspend.target" "hibernate.target" ];
  #    after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
  #    serviceConfig.Type = "oneshot";
  #    script = ''
  #      modprobe i2c_hid_acpi
  #      modprobe i2c_hid
  #      modprobe atkbd
  #      modprobe cros-ec-keyb
  #      modprobe btusb
  #    '';
  #  };

  systemd.services.disable-all-wakeups = {
    description = "Disable wakeup sources before suspend/hibernate";
    wantedBy = [ "suspend.target" "hibernate.target" ];
    before = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    path = [ pkgs.util-linux pkgs.findutils pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot"; # Fixed typo
      RemainAfterExit = true;
    };
    script = ''
      # Log what we're doing
      echo "Disabling wakeup sources..." | systemd-cat -t disable-wakeups

      # Disable specific problematic devices
      for device in LID0 H02C XHCI TXHC TDM0 TDM1 TRP0 TRP1 TRP2 TRP3; do
        if grep -q "^$device.*enabled" /proc/acpi/wakeup; then
          echo "Disabling $device" | systemd-cat -t disable-wakeups
          echo "$device" > /proc/acpi/wakeup 2>/dev/null || true
        fi
      done

      # Find and disable Chrome EC wakeup (multiple possible paths)
      for path in \
        /sys/class/chromeos/cros_ec/wakeup \
        /sys/devices/platform/GOOG0004:00/power/wakeup \
        /sys/devices/platform/PNP0C09:00/power/wakeup; do
        if [[ -f "$path" ]]; then
          echo "Disabling Chrome EC wakeup at $path" | systemd-cat -t disable-wakeups
          echo disabled > "$path" 2>/dev/null || true
        fi
      done

      # Disable Intel PMC wakeups
      find /sys/devices -path "*/intel_pmc_core*" -name "power/wakeup" 2>/dev/null | while read -r f; do
        echo disabled > "$f" 2>/dev/null || true
      done

      # Log final state
      echo "Final wakeup state:" | systemd-cat -t disable-wakeups
      cat /proc/acpi/wakeup | systemd-cat -t disable-wakeups
    '';
  };

  boot.blacklistedKernelModules = [
    "mei_hdcp"
    "mei_pxp"
    "mei"
    "vivaldi_fmap"
    "cros_kbd_led_backlight"
    "cros_ec_keyb"
    "cros_ec_light"
    "i915"
  ];

  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
