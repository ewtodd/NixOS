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
    services.son-of-anton = {
      enable = true;
      # One shared gateway under its own service account. Everything
      # model-related lives on son-of-anton (llama-swap, 10.0.0.5:8080).
      # Per-user CLI/TUI profiles: each account keeps its own
      # ~/.son-of-anton (addToSystemPackages stays false so the system-wide
      # SON_OF_ANTON_HOME export does not force everyone onto the gateway
      # state). The binary itself comes from home-manager.
      workingDirectory = "/scratch/son-of-anton";
      environmentFiles = [ config.age.secrets.son-of-anton-env.path ];
      environment = {
        # signal-cli HTTP daemon on mu (shared bot number).
        SIGNAL_HTTP_URL = "http://10.0.0.2:7583";
        # SearXNG on oracle.
        SEARXNG_URL = "http://10.0.0.6:8888/search";
      };
      settings = {
        model = {
          default = "qwen3.6-35b-a3b";
          provider = "custom";
        };
        # Route everything through litellm on oracle (10.0.0.6:4000), which
        # fronts llama-swap on son-of-anton and holds the master key.
        custom_providers.custom = {
          base_url = "http://10.0.0.6:4000/v1";
          key_env = "LITELLM_MASTER_KEY";
        };
        physics = {
          model = "qwen3.6-35b-a3b";
          base_url = "http://10.0.0.6:4000/v1";
          api_key_env = "LITELLM_MASTER_KEY";
        };
        router = {
          enabled = true;
          simple_model = "qwen3.8-27b-instruct";
          default_model = "qwen3.6-35b-a3b";
          planner_model = "qwen3.8-27b-coding";
          executor_model = "qwen3.8-27b-coding";
          reviewer_model = "qwen3.6-35b-a3b";
          researcher_model = "qwen3.8-27b-instruct";
        };
        web.backend = "searxng";
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
      "son-of-anton"
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
      "son-of-anton"
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
