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

  boot.loader.timeout = 0;
  boot.kernelParams = [
    "quiet"
    "loglevel=3"
    "systemd.show_status=false"
    "rd.udev.log_level=3"
  ];
  boot.consoleLogLevel = 0;

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
    bibata-cursors
  ];

  hardware.enableAllFirmware = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # The HDMI codec advertises 7.1 and lossless formats, but ACP ranks plain
  # stereo far above them, so the default profile never lets mpv negotiate a
  # bitstream. Prefer 7.1 for this card and keep the stereo profiles as fallback.
  services.pipewire.wireplumber.extraConfig."99-tony-hdmi-profile" = {
    "device.profile.priority.rules" = [
      {
        matches = [ { "device.name" = "alsa_card.pci-0000_00_1f.3"; } ];
        actions = {
          "update-props".priorities = [
            "output:hdmi-surround71"
            "output:hdmi-surround"
            "output:hdmi-stereo"
          ];
        };
      }
    ];
  };
}
