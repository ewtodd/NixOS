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

  # Straight to the TV: no bootloader menu, no fsck chatter, no login prompt.
  boot.loader.timeout = 0;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=false"
    "rd.udev.log_level=3"
  ];
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;

  # ── Hardware video decode ────────────────────────────────────────────────
  # graphics.intel.enable already pulls in intel-media-driver and vpl-gpu-rt.
  # What it does not set is the driver name: without this, libva can pick the
  # legacy i965 driver and Firefox silently falls back to software decode.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [ libva-utils ];

  # Comet Lake-LP uses the cAVS DSP, so audio comes up through SOF. HDMI output
  # is the whole point here, and a TV box coming up mute on the analog jack is
  # the classic failure -- verify with `aplay -l` and pick the HDMI sink.
  # pipewire and friends live behind deviceType.desktop/laptop in modules, and
  # this box is neither -- so audio has to be asked for explicitly, or the TV
  # gets a picture and silence.
  hardware.enableAllFirmware = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
