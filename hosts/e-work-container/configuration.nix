{ lib, ... }:

{
  # This is a NixOS configuration for a Lima VM running on Darwin
  imports = [ ];

  systemOptions = {
    graphics.amd.enable = false; # No hardware graphics in VM
    deviceType.desktop.enable = true; # Acts like a desktop
    services.ssh.enable = true;
    services.ai.enable = true;
    owner.e.enable = true;
  };

  # VM networking - Lima handles DHCP
  networking.hostName = "e-work-container";
  networking.useDHCP = lib.mkForce true;

  # Use systemd-resolved for DNS
  services.resolved.enable = true;

  # Enable SSH for remote access from Darwin host
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # Lima sets up its own auth
    };
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
    # Lima will set up its own SSH keys
  };

  # Minimal boot config for VM
  boot.plymouth.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # Root filesystem
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };

  # Read-only Nix store is mounted from Darwin via virtiofs
  # Local writes go to /nix/var
  fileSystems."/nix" = {
    device = "none";
    fsType = "virtiofs";
    options = [ "ro" ];
  };

  # Writable overlay for /nix/var (for profiles, gcroots, etc)
  fileSystems."/nix/var" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=0755" ];
  };

  time.timeZone = "America/New_York";
  system.stateVersion = "25.05";
}
