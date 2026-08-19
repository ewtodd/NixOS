{
  lib,
  pkgs,
  config,
  ...
}:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
  # Per-account subsets for temple TUI auth: the daemon maps a client's
  # pubkey to the OWNER of the first key file containing it, so keys must
  # appear in exactly one file or ownership is ambiguous.
  eplayKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
  eworkKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
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
    services.rgbLoad = {
      enable = true;
      backend = "openrgb";
    };
    hardware.suzyqable.enable = true;
    hardware.xbox.enable = true;
    deviceType.desktop.enable = true;
    services.ssh.enable = true;
    services.binaryCache.serve = true;
    services.suspend-then-hibernate.enable = true;
    services.wakeable.enable = true;
    services.nodeExporter.enable = true;
    # WireView Pro II GPU power monitor: Prometheus exporter + safety
    # watchdog (power off on sustained fault / over-temperature). The
    # WireView fault output is also wired to the mains switch as the
    # primary cut; this is software redundancy.
    services.wireview-monitor.enable = true;
    services.wireview-safety.enable = true;
    apps.docker.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
    services.temple-daemon = {
      enable = true;
      # Single shared agent instance under its own service account.
      # Session isolation: TUI clients authenticate by pubkey and only
      # ever see sessions owned by their key's file name (e-play vs
      # e-work, same DB). Signal handles all sessions with owner labels.
      serviceUser = "temple";
      # Everything model-related lives on son-of-anton.
      modelEndpoints = {
        "gemma-4-31b" = "http://10.0.0.5:8080/v1";
        "qwen3.6-27b-heretic" = "http://10.0.0.5:8080/v1";
        "gemma-4-31b-heretic" = "http://10.0.0.5:8080/v1";
        "qwen3.6-35b-a3b" = "http://10.0.0.5:8080/v1";
        "qwen3.8-27b" = "http://10.0.0.5:8080/v1";
      };
      defaultModel = "qwen3.6-35b-a3b";
      simpleModel = "qwen3.8-27b";
      plannerModel = "qwen3.8-27b";
      executorModel = "qwen3.8-27b";
      reviewerModel = "qwen3.6-35b-a3b";
      researcherModel = "qwen3.8-27b";
      routerModel = "supra-router";
      titleModel = "supra-title";
      searxngUrl = "http://10.0.0.6:8888/search";
      # Memory bridge to the Open WebUI on oracle.
      openWebUI = {
        enable = true;
        baseUrl = "http://10.0.0.6:8081";
        apiKeyEnv = "OPENWEBUI_API_KEY";
      };
      environmentFile = config.age.secrets.temple-server-env.path;
      # Token file for Signal /verify registration (written by
      # temple-server --generate-token, run as the temple user).
      authTokenFile = "/var/lib/temple/tokens";
      # Shared Signal number; signal-cli runs on mu.
      signal = {
        enable = true;
        socketAddr = "10.0.0.2:7583";
      };
      # The service account joins nixconfig so the flake-update cron can
      # write /etc/nixos (group-writable).
      supplementaryGroups = [ "nixconfig" ];
      readWritePaths = [ "/etc/nixos" ];
      gitSafeDirectories = [ "/etc/nixos" ];
      # Landlock: executed commands see a read-only fs except the session
      # cwd, allowed dirs, HOME, and /tmp + /dev.
      sandbox = {
        enable = true;
        extraWritableDirs = [ "/scratch" ];
      };
      authorizedKeys = {
        e-play = personalKeys;
        e-work = personalKeys;
      };
    };
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
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
    openssh.authorizedKeys.keys = personalKeys ++ [
      # Temple server on oracle — remote tool execution. Connections arrive
      # via the bastion's wake-and-relay (source = 10.0.0.2) or directly
      # from oracle (10.0.0.6).
      ''from="10.0.0.2,10.0.0.6",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtKDNPgyOKIfHSAsaTZJbI9uQyOxEevf6hK9c1Mn2Of temple@oracle''
    ];
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
    openssh.authorizedKeys.keys = personalKeys ++ [
      ''from="10.0.0.2,10.0.0.6",no-port-forwarding,no-X11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtKDNPgyOKIfHSAsaTZJbI9uQyOxEevf6hK9c1Mn2Of temple@oracle''
    ];
  };

  systemOptions.services.wakeable = {
    wiredInterface = "enp16s0";
    initrdNicModule = "r8169";
    initrdAuthorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEOzNCr4bzaMgmGGlYuFvkt7yRi8xgQ1kaSwxvJCiSMf bastion-initrd-unlock"
    ];
  };

  services.protonmail-bridge = {
    enable = true;
    # Secret-service backends for Proton Bridge's headless credential storage.
    path = with pkgs; [
      pass
      gnome-keyring
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
