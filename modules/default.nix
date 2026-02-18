{ lib, pkgs, ... }:
with lib;
{
  imports = [
    ./desktopEnvironment
    ./hardware
    ./packages
    ./security
    ./services
  ];

  options = {
    systemOptions = {
      graphics.amd.enable = mkEnableOption "AMD graphics";
      graphics.intel.enable = mkEnableOption "Intel graphics";

      audio.chromebook.enable = mkEnableOption "Chromebook audio fixes";

      hardware.suzyqable.enable = mkEnableOption "Suzyqable chromebook debugging support";
      hardware.fingerprint.enable = mkEnableOption "Fprintd support";
      hardware.openRGB.enable = mkEnableOption "openRGB support";

      deviceType.laptop.enable = mkEnableOption "Laptop-specific features";
      deviceType.desktop.enable = mkEnableOption "Desktop-specific features";

      apps.zoom.enable = mkEnableOption "Zoom";
      apps.remarkable.enable = mkEnableOption "Remarkable from wrapWine flake";
      apps.quickemu.enable = mkEnableOption "Quickemu";

      apps.niri.blur.enable = mkEnableOption "Whether to use WIP git branch of niri with blur support";

      services.ssh.enable = mkEnableOption "SSH with non-standard port";
      services.suspend-then-hibernate.enable = mkEnableOption "Suspend then hibernate";
      services.tailscale.enable = mkEnableOption "Literally just tailscale...";

      services.nixBuilder.server = {
        enable = mkEnableOption "Act as a Nix remote build server";
        authorizedKeys = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SSH public keys authorized to submit builds";
        };
      };

      services.nixBuilder.client = {
        enable = mkEnableOption "Use a remote Nix builder";
        builderHostName = mkOption {
          type = types.str;
          default = "e-desktop";
          description = "Hostname of the build server (use Tailscale hostname)";
        };
        sshKeyPath = mkOption {
          type = types.str;
          default = "/root/.ssh/nix-builder";
          description = "Path to the SSH private key for connecting to the builder";
        };
        maxJobs = mkOption {
          type = types.int;
          default = 16;
          description = "Max parallel jobs on the remote builder";
        };
      };

      security.harden.enable = mkEnableOption "Try to reasonably harden NixOS";

      owner.e.enable = mkEnableOption "Whether this is an e-device. If it isn't then it must be a v-device!";
    };
  };

  config = {
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    users.defaultUserShell = pkgs.bash;
    programs.bash = {
      enable = true;
      completion.enable = true;
    };

    networking = {
      firewall.enable = true;
      networkmanager.enable = true;
    };

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    systemd.tmpfiles.rules = [
      "Z /sys/class/powercap/intel-rapl:0/energy_uj 0444 root root - -"
    ];

    services.interception-tools = {
      enable = true;
      plugins = with pkgs.interception-tools-plugins; [
        caps2esc
        dual-function-keys
      ];
      udevmonConfig = ''
        - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
          DEVICE:
            EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
      '';
    };

    services.printing.enable = true;
    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;
    services.avahi.openFirewall = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    services.gnome.gnome-keyring.enable = true;

    security.polkit = {
      enable = true;
    };

    security.rtkit.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = false;
    };

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    boot.plymouth.enable = true;

    powerManagement.enable = true;

    nix.settings = {
      auto-optimise-store = true;
      download-buffer-size = 524288000;
    };

    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep 3";
      };
    };

    users.groups = {
      nixconfig = { };
    };

    environment.variables.EDITOR = "nvim";

    environment.shellAliases = {
      vim = "nvim";
      ":q" = "exit";
      nrs = "nh os switch /etc/nixos";
      fix-nixos-git = "sudo chown -R root:nixconfig /etc/nixos && sudo chmod -R 2775 /etc/nixos && git config --global --add safe.directory /etc/nixos && git -C /etc/nixos config core.fileMode false";
      init-dev-env = "nix flake init -t github:ewtodd/dev-env --refresh";
      init-latex-env = "nix flake init -t github:ewtodd/latex-env --refresh";
      init-geant4-env = "nix flake init -t github:ewtodd/geant4-env --refresh";
      init-analysis-env = "nix flake init -t github:ewtodd/Analysis-Utilities --refresh";
      view-image = "kitten icat";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
