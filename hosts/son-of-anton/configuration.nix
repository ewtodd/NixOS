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
    services.scheduledReboot.calendar = "Sun *-*-* 05:00:00";
    # vLLM on R9700s (TP=2): Qwen3.8-27B-FP8 with MTP
    services.vllm = {
      enable = true;
      lanExpose = true;
      model = "Qwen/Qwen3.8-27B-FP8";
      devices = "0,1";
      tensorParallelSize = 2;
      maxModelLen = 262144;
      kvCacheDtype = "fp8";
      maxNumSeqs = 4;
      gpuMemoryUtilization = 0.90;
      enforceEager = true;
      mtp = true;
      mtpTokens = 3;
      port = 8100;
      toolCallParser = "qwen3_xml";
      reasoningParser = "qwen3";
      languageModelOnly = false;
    };
    # llama.cpp on Strix (device 2): Qwen3.8-27B Q5 with MTP
    services.llamaSwap = {
      enable = true;
      lanExpose = true;
      backend = "rocm";
      cacheDir = "/scratch/llama-cache";
      models = {
        "qwen3.8-27b" = {
          hf = "unsloth/Qwen3.8-27B-GGUF:UD-Q5_K_XL";
          ctxSize = 524288;
          loadMode = "mlock";
          device = "ROCm2";
          parallel = 2;
          batchSize = 1024;
          ubatchSize = 512;
          flashAttn = "on";
          kQuant = "f16";
          vQuant = "f16";
          specType = "draft-mtp";
          specDraftNMax = 3;
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/resolve/main/mmproj-F16.gguf";
            hash = "sha256-y7hBqe4GNrLsFy9buN8uqN/rAekP58YSZYHWYqC05D4=";
          };
          mmprojDevice = "ROCm2";
          extraFlags = [
            "--temp 1.0"
            "--top-p 0.95"
          ];
        };
      };
    };
    security.harden.enable = true;
  };

  security.pam.loginLimits = [
    {
      domain = "son-of-anton";
      type = "hard";
      item = "memlock";
      value = "unlimited";
    }
  ];
  security.sudo-rs.extraRules = [
    {
      users = [ "son-of-anton" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tee /proc/sys/vm/drop_caches";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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
      "llama-cache"
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
