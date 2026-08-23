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
    ./environment.nix
    ./extra-packages.nix
    ./hardware-configuration.nix
  ];

  systemOptions = {
    graphics.amd.enable = true;
    deviceType.server.enable = true;
    services.rgbLoad = {
      enable = true;
      backend = "framework";
    };
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "*-*-* 05:00:00";
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "rocm";
      cacheDir = "/scratch/llama-cache";
      verboseLogging = true;
      models = {
        "deepseek-v4-flash-full" = {
          hf = "unsloth/DeepSeek-V4-Flash-0731-GGUF:UD-Q8_K_XL";
          ctxSize = 1048576;
          loadMode = "auto";
          batchSize = 2048;
          ubatchSize = 1024;
          solo = true;
          kQuant = "f16";
          vQuant = "f16";
          parallel = 2;
          flashAttn = "auto";
          device = "ROCm0,ROCm1,ROCm2";
          specType = "draft-dspark";
          specDraftNMax = 6;
          specDraftDevice = "ROCm2";
          specDraftHf = "unsloth/DeepSeek-V4-Flash-0731-GGUF:BF16";
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
          ];
        };
        "qwen3.6-35b-a3b" = {
          hf = "unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q8_K_XL";
          ctxSize = 524288;
          parallel = 2;
          loadMode = "mlock";
          device = "ROCm2";
          flashAttn = "on";
          kQuant = "q8_0";
          vQuant = "q8_0";
          reasoningPreserve = true;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-iXHuTzMf8KTGCTdPMphLPU5twIbAqjXx1jf60YKeiH8=";
          };
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];
        };
        "qwen3.8-27b" = {
          hf = "unsloth/Qwen3.8-27B-GGUF:UD-Q5_K_XL";
          ctxSize = 262144;
          loadMode = "mlock";
          device = "ROCm0";
          reasoningPreserve = true;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-y7hBqe4GNrLsFy9buN8uqN/rAekP58YSZYHWYqC05D4=";
          };
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
            "--top-k 20"
            "--min-p 0"
          ];
        };
      };
    };
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1151"
    "gfx1201"
  ];

  users.users.son-of-anton = {
    isNormalUser = true;
    description = "son-of-anton";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "video"
      "render"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  systemd.tmpfiles.rules = [
    "d /scratch 0775 son-of-anton users - -"
  ];

  time.timeZone = "America/Chicago";
  networking.hostName = "son-of-anton";
  system.stateVersion = "25.11";
}
