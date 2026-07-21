{ ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.asahi.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.nodeExporter.enable = true;
    services.templeServer.enable = true;
    services.litellmProxy.enable = true;
    services.searxng.enable = true;
    security.harden.enable = true;
  };

  users.users.oracle = {
    isNormalUser = true;
    description = "oracle";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "oracle";
  system.stateVersion = "26.11";

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "10.0.0.4";
      system = "aarch64-linux";
      sshUser = "deploy";
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
      maxJobs = 8;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
    }
  ];

}
