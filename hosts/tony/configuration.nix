{
  config,
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

  # change to @ 60 when get new cable
  outputName = "HDMI-A-2";
  outputMode = "3840x2160@30";

  kiosk = pkgs.writeShellApplication {
    name = "tony-kiosk";
    runtimeInputs = [
      config.home-manager.users.tony.programs.firefox.finalPackage
      pkgs.wlr-randr
    ];
    text = ''
      export MOZ_ENABLE_WAYLAND=1
            export MOZ_DISABLE_RDD_SANDBOX=1
      export LIBVA_DRIVER_NAME=iHD

            runtime="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      for _ in $(seq 1 300); do
        if [ -S "$runtime/pulse/native" ]; then break; fi
        sleep 0.1
      done

            wlr-randr --output ${outputName} --mode ${outputMode} || true

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
    graphics.intel.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.nodeExporter.enable = true;
    services.binaryCache.consume = true;
    security.harden.enable = true;
  };

  users.users.tony = {
    isNormalUser = true;
    uid = 1000;
    description = "living room";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "render"
      "input"
      "networkmanager"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  services.openssh.settings.AllowUsers = [ "tony" ];

  services.cage = {
    enable = true;
    user = "tony";
    program = lib.getExe kiosk;
  };

  systemd.services.cage-tty1.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "10s";
  };

  systemd.services.cage-tty1.unitConfig.StartLimitIntervalSec = 0;

  networking.hostName = "tony";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
