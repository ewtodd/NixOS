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
    ./storage.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.zfsMetrics.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "Sun *-*-* 05:15:00";
    security.harden.enable = true;
    services.backup.server = {
      enable = true;
      clients."e-desktop".publicKey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOIu7XnByPHkBJU+kEQ9EHwbgdqV7vlbHhdNQzaWFLc+ borg@e-desktop";
    };
  };

  nixpkgs.config.rocmTargets = [
    "gfx1201"
  ];

  users.users.anton = {
    isNormalUser = true;
    description = "anton";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "anton";
  # Unique ID required by ZFS to detect pool ownership across machines.
  networking.hostId = "ce97c19c";
  system.stateVersion = "25.11";
}
