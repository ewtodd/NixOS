{ ... }:
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
    services.vllm = {
      enable = true;
      lanExpose = true;
      extraFlags = [
        "--distributed-timeout-seconds 90"
        "--served-model-name Qwen/Qwen3.8-27B-FP8"
      ];
      extraEnv = {
        TORCH_NCCL_DUMP_ON_TIMEOUT = "0";
        VLLM_SLEEP_WHEN_IDLE = "1";
      };
      # llmfan46/Qwen3.8-27B-Ultra-Uncensored-Heretic-Native-MTP-Preserved, cast to
      # Qwen's block-fp8 layout with bf16_to_qwen_fp8.py (tensor-identical to Qwen/Qwen3.8-27B-FP8).
      model = "/scratch/models/Qwen3.8-27B-Heretic-FP8";
      devices = "0,1";
      tensorParallelSize = 2;
      maxModelLen = 262144;
      kvCacheDtype = "fp8";
      maxNumSeqs = 4;
      gpuMemoryUtilization = 0.92;
      enforceEager = true;
      mtp = true;
      mtpTokens = 3;
      port = 8100;
      toolCallParser = "qwen3_xml";
      reasoningParser = "qwen3";
      languageModelOnly = false;
    };
    # Qwen3.8-Next-Flash on the Strix Halo iGPU via pwilkin's llama.cpp
    # strix-halo branch (replaces antirez/ds4 DeepSeek-V4). Weights are the
    # ilintar/qwen3.8-flash-next-gguf-strix-halo IQ4_NL PROJFIX shards plus the
    # shared-embedding MTP draft, downloaded with `hf download --local-dir`.
    services.llamaStrix = {
      enable = true;
      lanExpose = true;
      model = "/scratch/llama-cache/qwen3.8-flash-next-strix-halo/Qwen3.8-Flash-Next-IQ4_NL-PROJFIX-00001-of-00009.gguf";
      port = 8050;
      parallel = 1;
      ctxSize = 524288;
      ropeScaling = "yarn";
      ropeScale = 2;
      yarnOrigCtx = 262144;
      ctxTrainOverride = 524288;
      mmproj = "/scratch/llama-cache/qwen3.8-flash-next-strix-halo/mmproj-Qwen3.8-Flash-Next-bf16.gguf";
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
