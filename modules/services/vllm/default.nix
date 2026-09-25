{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.vllm;

  stack = import ./pkgs {
    inherit pkgs;
    r4dSrc = inputs.libr4d-src;
    radianceSrc = inputs.vllm-radiance-src;
  };
  inherit (stack)
    pythonEnv
    rocmSdk
    rocmSdkCc
    runtimeLibs
    gfxArch
    ;

  radianceEnv = {
    RADIANCE_GFX_ARCH = gfxArch;
    RADIANCE_USE_R4D = "1";
    RADIANCE_USE_R4D_GDN = "1";
    RADIANCE_R4D_REPORT = "1";
    RADIANCE_USE_R4D_AR = "1";
    RADIANCE_USE_R4D_AR_QUANT = "1";
    RADIANCE_SKINNY_GEMM = "1";
    RADIANCE_GDN_META = "1";
    RADIANCE_GDN_MERGE_INPROJ = "1";
    RADIANCE_GDN_FUSED_UPDATE = "1";
    RADIANCE_GDN_FUSED_MAX_ITEMS = "32";
    RADIANCE_GDN_SHARED_BUILD = "1";
    RADIANCE_TOPK_TRITON_MIN_ROWS = "1";
    RADIANCE_TOPK_COMPOSITE = "1";
    RADIANCE_TOPK_COMPOSITE_KCAP = "64";
    RADIANCE_MXFP4 = "1";
    RADIANCE_MXFP4_W4A8 = "1";
    RADIANCE_MXFP4_W4A8_MIN_M = "0";
    RADIANCE_MXFP4_DECODE_MAX_M = "64";
    RADIANCE_MXFP4_TN4_MIN_M = "2048";
    RADIANCE_MXFP4_WPERM = "1";
    RADIANCE_MXFP4_DECODE_NT = "1";
    RADIANCE_QUARK_BF16_MTP = "1";
    RADIANCE_KV_GROUP_OPT = "1";
    RADIANCE_AR_QNT = "1024";
    RADIANCE_AR_QNB = "96";
    RADIANCE_PRESHUFFLE = "1";
    RADIANCE_ATTN_TUNE = "1";
    RADIANCE_FUSE_RMS_QUANT = "1";
    RADIANCE_DYNAMIC_DRAFT = "1";
    RADIANCE_DRAFT_SCHEDULE = "1:8,2:7,4:6,8:5,16:4";
    RADIANCE_DRAFT_TAU = "0.28";
    RADIANCE_DYNAMIC_WIDTH = "1";
    RADIANCE_DYNW_MIN_BATCH = "5";
    RADIANCE_DRAFT_RERANK = "64";
    RADIANCE_VERIFY_HEAD = "1";
    R4D_ATTN_FP8 = "0";
    RADIANCE_FAST_DRAFT = if cfg.fastDraft then "1" else "0";
    RADIANCE_RUN_BWTEST = "0";
  };

  aiterEnv = {
    VLLM_ROCM_USE_AITER = "1";
    VLLM_ROCM_USE_AITER_UNIFIED_ATTENTION = "1";
    VLLM_ROCM_USE_AITER_MHA = "0";
    VLLM_ROCM_USE_AITER_MLA = "0";
    VLLM_ROCM_USE_AITER_MOE = "0";
    VLLM_ROCM_USE_AITER_LINEAR = "0";
    VLLM_ROCM_USE_AITER_FP8BMM = "0";
    VLLM_ROCM_USE_AITER_FP4BMM = "0";
    VLLM_ROCM_USE_AITER_TRITON_GEMM = "0";
    VLLM_ROCM_USE_AITER_RMSNORM = "0";
  };

  rocmEnv = {
    ROCM_PATH = "${rocmSdk}";
    ROCM_HOME = "${rocmSdk}";
    HIP_PATH = "${rocmSdk}";
    HIP_PLATFORM = "amd";
    HIP_CLANG_PATH = "${rocmSdkCc}/llvm/bin";
    HIP_DEVICE_LIB_PATH = "${rocmSdk}/lib/llvm/amdgcn/bitcode";
    LD_LIBRARY_PATH = runtimeLibs;
    TRITON_LIBHIP_PATH = "${rocmSdk}/lib/libamdhip64.so";
    PYTORCH_ROCM_ARCH = gfxArch;
    HIP_ARCHITECTURES = gfxArch;
    AMDGPU_TARGETS = gfxArch;
    GPU_ARCHS = gfxArch;
    HIP_VISIBLE_DEVICES = cfg.devices;
    HIP_FORCE_DEV_KERNARG = "0";
    TORCH_BLAS_PREFER_HIPBLASLT = "0";
    GPU_MAX_HW_QUEUES = "1";
    SAFETENSORS_FAST_GPU = "1";
    TOKENIZERS_PARALLELISM = "false";
    TRITON_CACHE_AUTOTUNING = "1";
    VLLM_TARGET_DEVICE = "rocm";
    HF_HOME = cfg.modelCache;
    HF_HUB_CACHE = cfg.modelCache;
    AITER_JIT_DIR = "${cfg.cacheDir}/aiter-jit";
    TRITON_CACHE_DIR = "${cfg.cacheDir}/triton";
    VLLM_CACHE_ROOT = "${cfg.cacheDir}/vllm";
    TORCHINDUCTOR_CACHE_DIR = "${cfg.cacheDir}/inductor";
  };

  serviceEnv = rocmEnv // aiterEnv // radianceEnv // cfg.extraEnv;

  specConfig = builtins.toJSON {
    method = "mtp";
    num_speculative_tokens = cfg.mtpTokens;
    attention_backend = cfg.attentionBackend;
    disable_padded_drafter_batch = true;
  };

  serveArgs = [
    cfg.model
    "--tensor-parallel-size ${toString cfg.tensorParallelSize}"
    "--max-model-len ${toString cfg.maxModelLen}"
    "--max-num-seqs ${toString cfg.maxNumSeqs}"
    "--max-num-batched-tokens ${toString cfg.maxNumBatchedTokens}"
    "--gpu-memory-utilization ${toString cfg.gpuMemoryUtilization}"
    "--kv-cache-dtype ${cfg.kvCacheDtype}"
    "--attention-backend ${cfg.attentionBackend}"
    "--generation-config auto"
    "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
    "--port ${toString cfg.port}"
  ]
  ++ lib.optionals (cfg.quantization != null) [ "--quantization ${cfg.quantization}" ]
  ++ lib.optionals cfg.prefixCaching [
    "--enable-prefix-caching"
    "--mamba-cache-mode align"
  ]
  ++ lib.optionals cfg.mtp [
    "--speculative-config ${lib.escapeShellArg specConfig}"
    "--no-async-scheduling"
  ]
  ++ lib.optionals cfg.enforceEager [ "--enforce-eager" ]
  ++ lib.optionals cfg.languageModelOnly [ "--language-model-only" ]
  ++ lib.optionals (cfg.toolCallParser != null) [
    "--enable-auto-tool-choice"
    "--tool-call-parser ${cfg.toolCallParser}"
  ]
  ++ lib.optionals (cfg.reasoningParser != null) [ "--reasoning-parser ${cfg.reasoningParser}" ]
  ++ lib.optionals (cfg.chatTemplate != null) [ "--chat-template ${cfg.chatTemplate}" ]
  ++ lib.optionals (cfg.hfOverrides != { }) [
    "--hf-overrides ${lib.escapeShellArg (builtins.toJSON cfg.hfOverrides)}"
  ]
  ++ cfg.extraFlags;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d ${cfg.cacheDir} 0755 ${cfg.user} users -"
    ];

    systemd.services.vllm = {
      description = "vLLM inference server (${cfg.model})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = serviceEnv;
      path = [
        rocmSdkCc
        rocmSdk
        pkgs.gcc
      ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${pythonEnv}/bin/vllm serve ${lib.concatStringsSep " " serveArgs}";
        # vLLM exits 0 after EngineDeadError, so on-failure never fires — the box
        # sat dead for an hour on 2026-08-29. Always is the only correct setting here.
        Restart = "always";
        RestartSec = 10;
        LimitMEMLOCK = "infinity";
        SupplementaryGroups = [
          "video"
          "render"
        ];
      };
    };
  };
}
