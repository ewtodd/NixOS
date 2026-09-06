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
    services.scheduledReboot.enable = true;
    # Was daily "for as long as it is not ZFS". The pool exists now, so weekly:
    # still picks up kernel/closure updates, without interrupting a scrub or a
    # resilver every single night. Both resume across a reboot, so this is about
    # not being pointlessly disruptive on a file server rather than about risk.
    services.scheduledReboot.calendar = "Sun *-*-* 05:15:00";
    security.harden.enable = true;
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
