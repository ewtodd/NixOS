{ pkgs, ... }:
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
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    # reboot daily, for as long as it is not ZFS
    services.scheduledReboot.calendar = "*-*-* 05:15:00";
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "rocm";
      cacheDir = "/var/cache/llama-cache";
      models = {
        "qwen3.6-27b" = {
          hf = "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q5_K_XL";
          ctxSize = 179200;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];
        };
        "gemma-4-31b" = {
          hf = "unsloth/gemma-4-31B-it-GGUF:UD-Q5_K_XL";
          ctxSize = 262144;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-btzKIoITwo01Z6NdIvhJ7qUtg2CHUJOFGVmt9dLycOs=";
          };
        };
        "qwen3.6-27b-heretic" = {
          hf = "llmfan46/Qwen3.6-27B-uncensored-heretic-v2-Native-MTP-Preserved-GGUF:Q6_K";
          ctxSize = 179200;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--spec-type draft-mtp"
            "--spec-draft-n-max 2"
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/llmfan46/Qwen3.6-27B-uncensored-heretic-v2-Native-MTP-Preserved-GGUF/resolve/main/Qwen3.6-27B-mmproj-BF16.gguf";
            hash = "sha256-xcjEHabRVaYe3SG346pQtu938SLVAtNq/kpNXD5JTU8=";
          };
        };
        "gemma-4-31b-heretic" = {
          hf = "llmfan46/gemma-4-31B-it-uncensored-heretic-GGUF:Q5_K_M";
          ctxSize = 262144;
          mlock = false;
          kvQuant = true;
          extraFlags = [
            "--temp 1.0"
            "--top-k 64"
            "--top-p 0.95"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/llmfan46/gemma-4-31B-it-uncensored-heretic-GGUF/resolve/main/gemma-4-31B-it-mmproj-BF16.gguf";
            hash = "sha256-IUh/8m0I993R1lTTu/wa4QIKqzEZ9b9lR0LORpdzLk4=";
          };
        };

      };
    };
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1201"
  ];

  users.users.anton = {
    isNormalUser = true;
    description = "anton";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "anton";
  # Unique ID required by ZFS to detect pool ownership across machines.
  networking.hostId = "ce97c19c";
  system.stateVersion = "25.11";
}
