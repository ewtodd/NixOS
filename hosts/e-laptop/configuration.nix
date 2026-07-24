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
    hardware.chromebook-audio.enable = true;
    deviceType.laptop.enable = true;
    services.suspend-then-hibernate.enable = true;
    services.binaryCache.consume = true;
    security.harden.enable = true;
    owner.e.enable = true;
    services.temple-daemon = {
      enable = true;
      daemons = {
        "e-play" = {
          cwd = "/home/e-play/Software";
        };
        "e-work" = {
          cwd = "/home/e-work";
        };
      };
    };
  };

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "input"
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "render"
      "video"
      "lp"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "input"
      "nixconfig"
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "e-laptop";
  system.stateVersion = "25.11";

}
