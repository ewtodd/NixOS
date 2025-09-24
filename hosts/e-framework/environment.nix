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
    "xe.modeset=1"
    "xe.enable_display_power_well=0"
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

  systemd.services.mod-pre-sleep = {
    description = "Unload problematic modules before hibernate";
    wantedBy = [ "hibernate.target" ];
    before = [ "hibernate.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      rmmod intel_hid 2>/dev/null || true
      rmmod i8042 2>/dev/null || true 
      echo 0 > /dev/cpu_dma_latency || true 
      cat /sys/module/intel_idle/parameters/max_cstate > /tmp/original_cstate 2>/dev/null || echo "8" > /tmp/original_cstate
    '';
  };

  systemd.services.mod-resume = {
    description = "Reload modules after resume";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig.Type = "oneshot";
    path = [ pkgs.kmod ];
    script = ''
      modprobe i8042 2>/dev/null || true
      modprobe intel_hid 2>/dev/null || true
      if [ -f /tmp/original_cstate ]; then
      cat /tmp/original_cstate > /sys/module/intel_idle/parameters/max_cstate 2>/dev/null || true
      rm -f /tmp/original_cstate
      fi 
      # Remove DMA latency constraint
      echo 2000000000 > /dev/cpu_dma_latency || true
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
