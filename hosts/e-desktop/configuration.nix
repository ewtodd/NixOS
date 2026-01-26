{ ... }:

{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    hardware.suzyqable.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.tailscale.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
  };

  nixpkgs.config.rocmTargets = [ "gfx1100" ];

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
      "docker"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
      "docker"
    ];
  };

  time.timeZone = "America/New_York";
  networking.hostName = "e-desktop";
  system.stateVersion = "24.11";

}
