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
    # The compositor draws the cursor, so this has to be cage's own
    # environment -- exporting it in the kiosk wrapper would be too late.
    #
    # 240 is 10x the 24px default. At 3840x2160 viewed from a sofa the default
    # is a few millimetres of screen and effectively invisible. Bibata ships
    # large bitmaps (its left_ptr is 173 KB of multiple sizes), so this stays
    # sharp instead of scaling up a 48px source into mush.
    environment = {
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "240";
    };
  };

  systemd.services.cage-tty1.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "10s";
  };

  systemd.services.cage-tty1.unitConfig.StartLimitIntervalSec = 0;

  # Session cookies only die when the browser process does, and a kiosk browser
  # never exits on its own -- so nothing above would ever take effect. A nightly
  # restart is what actually clears YouTube, and it doubles as cheap hygiene for
  # a long-running compositor. 04:00 so it is never mid-film.
  systemd.services.tony-nightly-restart = {
    description = "Restart the kiosk session (drops YouTube session cookies)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart cage-tty1.service";
    };
  };
  systemd.timers.tony-nightly-restart = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = false;
      RandomizedDelaySec = "5m";
    };
  };

  networking.hostName = "tony";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Chicago";
  system.stateVersion = "25.11";
}
