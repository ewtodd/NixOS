{ ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINoytDv0UZeMmWFoYaGQkLpTdOmo7iefXmZmgxM4FxVb soa-ricky@e-desktop"
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
        "--served-model-name qwen3.8-27b"
      ];
      extraEnv = {
        TORCH_NCCL_DUMP_ON_TIMEOUT = "0";
        # ParoQuant int5 W5A8 profile from run_paroquant.sh: int8 per-group
        # activations plus the zero-point epilogue; explicit settings win over
        # the kernel defaults.
        RADIANCE_PQ_I8 = "1";
        RADIANCE_PQ_PG = "1";
        RADIANCE_PQ_ZPE = "1";
        RADIANCE_PQ_WPERM = "1";
        RADIANCE_PQ_DECODE_NT = "1";
        RADIANCE_PQ_ATILED = "1";
        RADIANCE_PQ_PTOK = "1";
        RADIANCE_PQ_FUSED_TOKQ = "1";
        RADIANCE_PQ_ROT_STREAM = "1";
        RADIANCE_PQ_ROT_STREAM2 = "1";
        RADIANCE_PQ_ROT_STREAM3 = "0";
        RADIANCE_PQ_PG_PRODUCER = "3";
        RADIANCE_PQ_ROT_V2 = "1";
        RADIANCE_PQ_CHECK_MAX_M = "128";
        RADIANCE_PQ_DECODE_MAX_M = "64";
      };
      # Production: Swift-1.5 Quark RTN MXFP4 served with the native W4A16
      # (bf16-activation weight-only) kernel from my fork. The weight-only
      # config dir drops input_tensors; quant_method comes from the checkpoint.
      model = "/scratch/vllm-models/Swift-1.5-Qwen3.8-27b-Quark-RTN-MXFP4-W4A16";
      quantization = null;
      mxfp4 = true;
      mxfp4W4A16 = true;
      devices = "0,1";
      tensorParallelSize = 2;
      maxModelLen = 393216;
      hfOverrides.text_config.rope_parameters = {
        rope_type = "yarn";
        factor = 2;
        original_max_position_embeddings = 262144;
        mrope_interleaved = true;
        mrope_section = [
          11
          11
          10
        ];
        partial_rotary_factor = 0.25;
        rope_theta = 10000000;
      };
      kvCacheDtype = "fp8";
      maxNumSeqs = 4;
      gpuMemoryUtilization = 0.98;
      # Codeberg production shape: inductor + piecewise cudagraphs. The
      # radiance fusion passes (rmsquant, stream producers, GDN glue) only
      # run under compilation; eager left decode ~10x slower.
      compilationConfig = {
        cudagraph_mode = "PIECEWISE";
      };
      # Production draft controller (DFlash2, K=7). Set false only for
      # target-only measurement runs.
      speculative = true;
      speculativeMethod = "dflash";
      speculativeTokens = 5;
      draftModel = "/scratch/vllm-models/Qwen3.8-27B-DFlash2-FP8/";
      draftAttentionBackend = "TRITON_ATTN";
      draftTensorParallelSize = 2;
      draftMaxModelLen = 393216;
      fastDraft = true;
      port = 8100;
      toolCallParser = "qwen3_xml";
      reasoningParser = "qwen3";
      languageModelOnly = false;
    };
    services.gufoStrix = {
      enable = true;
      lanExpose = true;
      model = "/scratch/models/gufo/qwen3.8-flash-next/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
      mtpModel = "/scratch/models/gufo/qwen3.8-flash-next/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
      mmproj = "/scratch/models/gufo/qwen3.8-flash-next/mmproj-BF16.gguf";
      sessions = 2;
      context = 262144;
      port = 8050;
    };
    security.harden.enable = true;
  };

  nixpkgs.config.rocmTargets = [
    "gfx1151"
    "gfx1201"
  ];
  users.groups.llama-cache = { };

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
