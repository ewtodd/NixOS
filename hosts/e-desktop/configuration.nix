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

    services.nixBuilder.server = {
      enable = true;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPAzgPdwGaA6mb++GnW0jw4sp2Y0sMfgT7J26KcMXsc root@e-laptop"
      ];
    };
  };

  nixpkgs.config.rocmTargets = [ "gfx1100" ];

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "nixconfig"
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
      "nixconfig"
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
