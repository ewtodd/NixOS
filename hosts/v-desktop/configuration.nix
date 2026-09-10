{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    services.rgbStatic = {
      enable = true;
      # Hand-matched by eye so the board headers read as the same pink as the
      # RAM and the GPU shroud; recovered from the "pink!!!" OpenRGB profile.
      defaultColor = "F600C9";
      deviceColors = {
        "MSI MPG" = "FF0B71";
      };
      # Two DIMMs, the GPU and the board. The DIMMs are found straight away and
      # the other two take a few seconds, so without this the case fans get
      # left dark.
      expectedDevices = 4;
    };
    hardware.openRGB.enable = true;
    hardware.xbox.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.binaryCache.consume = true;
    owner.v.enable = true;
    services.suspend-then-hibernate.enable = true;
    apps.zoom.enable = true;
    apps.remarkable.enable = true;
    apps.quickemu.enable = true;
    apps.docker.enable = true;
  };

  nixpkgs.config.rocmTargets = [ "gfx1201" ];

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
      "udev"
    ];
  };

  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
      "udev"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "v-desktop";
  system.stateVersion = "25.05";
}
