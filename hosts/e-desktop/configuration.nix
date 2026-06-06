{ lib, ... }:
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
    ./extra-packages.nix
    ./hardware-configuration.nix
    ./environment.nix
    ./encrypted-volumes.nix
  ];

  systemOptions = {
    graphics.nvidia.enable = true;

    hardware.openRGB.enable = true;
    hardware.suzyqable.enable = true;
    hardware.xbox.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.suspend-then-hibernate.enable = true;
    services.binaryCache.serve = true;
    services.wakeable.enable = true;
    services.nodeExporter.enable = true;
    apps.docker.enable = true;
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
      "video"
      "lp"
      "docker"
      "i2c"
    ];
    openssh.authorizedKeys.keys = personalKeys;
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
      "i2c"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  systemOptions.services.wakeable = {
    wiredInterface = "enp16s0";
    initrdNicModule = "r8169";
    initrdAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOzNCr4bzaMgmGGlYuFvkt7yRi8xgQ1kaSwxvJCiSMf bastion-initrd-unlock"
    ];
  };

  networking.networkmanager = {
    connectionConfig."ethernet.cloned-mac-address" = lib.mkForce "permanent";
    settings.main.no-auto-default = "*";
    ensureProfiles.profiles.wired = {
      connection = {
        id = "wired";
        type = "ethernet";
        interface-name = "enp16s0";
        autoconnect = true;
      };
      ethernet.cloned-mac-address = "permanent";
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "e-desktop";
  system.stateVersion = "24.11";

}
