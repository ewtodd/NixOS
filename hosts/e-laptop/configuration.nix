{ ... }:
{
  imports = [
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.intel.enable = true;
    hardware.xbox.enable = true;
    hardware.twoinone.enable = true;
    hardware.fingerprint.enable = true;
    deviceType.laptop.enable = true;
    services.suspend-then-hibernate.enable = true;
    services.orgmode-sync.enable = true;
    services.tailscale.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
  };

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "render"
      "video"
      "lp"
      "tss"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
      "tss"
    ];
  };

  time.timeZone = "America/New_York";
  networking.hostName = "e-laptop";
  system.stateVersion = "25.11";

}
