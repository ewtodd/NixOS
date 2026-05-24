{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.tailscale.enable = true;
    services.binaryCache.consume = true;
    security.harden.enable = true;
  };

  users.users.nu = {
    isNormalUser = true;
    description = "nu";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "server-nu";
  system.stateVersion = "25.11";
}
