{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];

  niri = config.home-manager.users.tony.wayland.windowManager.niri.package;
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

  systemd.services.kiosk = {
    description = "niri kiosk session on tty1";
    after = [
      "systemd-user-sessions.service"
      "systemd-logind.service"
      "getty@tty1.service"
    ];
    wants = [
      "dbus.socket"
      "systemd-logind.service"
    ];
    before = [ "graphical.target" ];
    wantedBy = [ "graphical.target" ];
    conflicts = [ "getty@tty1.service" ];
    # A deploy must not cut off a film; the 04:00 restart picks up the change.
    restartIfChanged = false;
    unitConfig = {
      ConditionPathExists = "/dev/tty1";
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      ExecStart = lib.getExe niri;
      User = "tony";
      PAMName = "kiosk";
      UtmpIdentifier = "%n";
      UtmpMode = "user";
      TTYPath = "/dev/tty1";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      StandardInput = "tty-fail";
      StandardOutput = "journal";
      StandardError = "journal";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # The stack nixpkgs' cage module used. systemd's PAMName never runs auth, so
  # what matters is the session part: pam_env for environment.sessionVariables
  # (XCURSOR_PATH, LIBVA_DRIVER_NAME) and pam_systemd for the logind seat
  # session niri opens the GPU and input devices through.
  security.pam.services.kiosk = {
    useDefaultRules = false;
    rules = {
      auth = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = config.security.pam.pam_unixModulePath;
          settings.nullok = true;
        }
      ];
      account = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = config.security.pam.pam_unixModulePath;
        }
      ];
      session = utils.pam.autoOrderRules [
        {
          name = "unix";
          control = "required";
          modulePath = config.security.pam.pam_unixModulePath;
        }
        {
          name = "env";
          control = "required";
          modulePath = "${config.security.pam.package}/lib/security/pam_env.so";
          settings.conffile = "/etc/pam/environment";
          settings.readenv = 0;
        }
        {
          name = "systemd";
          control = "required";
          modulePath = "${config.systemd.package}/lib/security/pam_systemd.so";
        }
      ];
    };
  };

  systemd.defaultUnit = "graphical.target";

  # Session cookies only die when the browser process does, and a kiosk browser
  # never exits on its own -- so nothing above would ever take effect. A nightly
  # restart is what actually clears YouTube, and it doubles as cheap hygiene for
  # a long-running compositor. 04:00 so it is never mid-film.
  systemd.services.tony-nightly-restart = {
    description = "Restart the kiosk session (drops YouTube session cookies)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart kiosk.service";
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
