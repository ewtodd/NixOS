{
  lib,
  pkgs,
  ...
}:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];

  # cage runs exactly one program, so the browser has to be its own wrapper.
  kiosk = pkgs.writeShellApplication {
    name = "tony-kiosk";
    runtimeInputs = [ pkgs.firefox ];
    text = ''
      export MOZ_ENABLE_WAYLAND=1
      # VAAPI decoding happens in the RDD process, whose sandbox blocks the
      # render node on some setups; without this Firefox falls back to software
      # and this 15 W part cannot keep up with 4K.
      export MOZ_DISABLE_RDD_SANDBOX=1
      export LIBVA_DRIVER_NAME=iHD
      # Homepage is set declaratively in home.nix; --kiosk hides all chrome and
      # Alt+Home returns here.
      exec firefox --kiosk
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    # Deliberately no deviceType: desktop/laptop would drag in the whole niri
    # session, and server strips the audio stack this needs.
    graphics.intel.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.nodeExporter.enable = true;
    services.binaryCache.consume = true;
    security.harden.enable = true;
  };

  # Pinned on purpose. The e-desktop migration lost every service account's
  # state because uids were allocated fresh by the installer and the restored
  # files kept their old numeric owners.
  users.users.tony = {
    isNormalUser = true;
    uid = 1000;
    description = "living room";
    extraGroups = [
      "video"
      "audio"
      "render"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  # Single-app Wayland compositor: no WM to fight, nothing to fall out to, and
  # it brings its own autologin.
  services.cage = {
    enable = true;
    user = "tony";
    program = lib.getExe kiosk;
  };

  networking.hostName = "tony";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
