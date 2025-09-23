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
  ];
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=3
  '';

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

  boot.blacklistedKernelModules =
    [ "mei_hdcp" "mei_pxp" "mei" "cros_kbd_led_backlight" ];

  boot.resumeDevice = "/dev/disk/by-uuid/125110a9-9ead-4526-bd82-a7f208b2ec3b";

}
