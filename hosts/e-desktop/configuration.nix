{ lib, ... }:
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
    services.suspend-then-hibernate.enable = true;
    services.binaryCache.serve = true;
    services.wakeable.enable = true;
    services.nodeExporter.enable = true;
    apps.docker.enable = true;
    security.harden.enable = true;
    owner.e.enable = true;
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "cuda";
      cacheDir = "/var/cache/llama-cache";
      models = {
        "fast-gemma-4-12b-it" = {
          hf = "unsloth/gemma-4-12b-it-GGUF:UD-Q8_K_XL";
          ctxSize = 131072;
          mlock = false;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
          ];
        };
        "fast-qwen3.6-27b" = {
          hf = "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL";
          ctxSize = 65536;
          mlock = false;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];
        };
      };
    };
  };

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
