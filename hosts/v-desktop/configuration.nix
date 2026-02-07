{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    hardware.openRGB.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.tailscale.enable = true;
    apps.zoom.enable = true;
    apps.remarkable.enable = true;
    apps.quickemu.enable = true;
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
