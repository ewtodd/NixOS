{ ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5aPPhXY+RssvL9znCFwHjkmUdi4KQkNSnAgd+AQqqx ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQQfBHV/kgznCsuV6uUbEUW5bb5WKx3vvWhQAAOmlZJ ethan-laptop-eplay"
  ];
in
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
    services.bastion.enable = true;
    services.nextcloud.enable = true;
    services.minecraft.enable = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 04:30:00";
    security.harden.enable = true;
  };

  users.users.mu = {
    isNormalUser = true;
    description = "mu";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "server-mu";
  system.stateVersion = "25.11";
}
