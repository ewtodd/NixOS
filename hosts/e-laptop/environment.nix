{
  pkgs,
  ...
}:
{

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.firmware = [ pkgs.linux-firmware ];

  boot.initrd.systemd.enable = true;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.resumeDevice = "/dev/disk/by-uuid/dd69ebd9-22ff-45c6-8af6-69757eec2508";
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "acpi.ec_no_wakeup=1"
    "i915.enable_psr=1"
    "i915.enable_fbc=1"
    "i915.fastboot=1"
    "pcie_aspm.policy=powersupersave"
  ];

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1 power_save_controller=Y
  '';

  environment.etc."tuned/active_profile".text = "powersave\n";
  environment.etc."tuned/profile_mode".text = "manual\n";

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTRS{vendor}=="0x10ec", ATTRS{class}=="0x010802", ATTR{power/control}="auto"
  '';

  systemd.services.disable-all-wakeups = {
    description = "Disable wakeup sources before suspend";
    wantedBy = [ "suspend.target" ];
    before = [ "systemd-suspend.service" ];
    path = [
      pkgs.util-linux
      pkgs.findutils
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      echo "Disabling wakeup sources..." | systemd-cat -t disable-wakeups

      for device in LID0 H02C XHCI TXHC TDM0 TDM1 TRP0 TRP1 TRP2 TRP3; do
        if grep -q "^$device.*enabled" /proc/acpi/wakeup; then
          echo "Disabling $device" | systemd-cat -t disable-wakeups
          echo "$device" > /proc/acpi/wakeup 2>/dev/null || true
        fi
      done

      for path in \
        /sys/class/chromeos/cros_ec/wakeup \
        /sys/devices/platform/GOOG0004:00/power/wakeup \
        /sys/devices/platform/PNP0C09:00/power/wakeup; do
        if [[ -f "$path" ]]; then
          echo "Disabling Chrome EC wakeup at $path" | systemd-cat -t disable-wakeups
          echo disabled > "$path" 2>/dev/null || true
        fi
      done

      find /sys/devices -path "*/intel_pmc_core*" -name "power/wakeup" 2>/dev/null | while read -r f; do
        echo disabled > "$f" 2>/dev/null || true
      done

      echo "Final wakeup state:" | systemd-cat -t disable-wakeups
      cat /proc/acpi/wakeup | systemd-cat -t disable-wakeups
    '';
  };

  boot.blacklistedKernelModules = [
    "cros_kbd_led_backlight"
    "snd_soc_avs"
    "snd_soc_hda_codec"
    "snd_intel_dspcfg"
    "snd_intel_sdw_acpi"
    "snd_sof_intel_hda_generic"
    "snd_sof_intel_hda"
    "snd_sof_intel_hda_common"
    "snd_sof_intel_hda_mlink"
    "snd_sof_intel_hda_sdw_bpt"
    "snd_sof_probes"
  ];
}
