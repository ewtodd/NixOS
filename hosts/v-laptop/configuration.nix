{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.intel.enable = true;
    deviceType.laptop.enable = true;
    hardware.fingerprint.enable = true;
    services.tailscale.enable = true;
    apps.zoom.enable = true;
    apps.remarkable.enable = true;
  };

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
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
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "v-laptop";
  system.stateVersion = "25.05";
}
