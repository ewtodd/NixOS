{
  pkgs,
  lib,
  unstable,
  ...
}:
{
  boot.kernelPackages = unstable.linuxPackages_latest;
  hardware.firmware = [ unstable.linux-firmware ];

  boot.initrd.systemd.enable = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "acpi.ec_no_wakeup=1"
  ];

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
