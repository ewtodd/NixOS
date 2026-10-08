{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.systemOptions.services.vllm;

  stack = inputs.vllm-radiance-src.lib.${pkgs.stdenv.hostPlatform.system}.mkVllmStack {
    inherit pkgs;
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
    RADIANCE_MXFP4 = if cfg.mxfp4 then "1" else "0";
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
  }
  // lib.optionalAttrs cfg.mxfp4 {
    RADIANCE_QUARK_BF16_MTP = "1";
  }
  // lib.optionalAttrs (cfg.mxfp4 && !cfg.mxfp4W4A16) {
    RADIANCE_MXFP4_W4A8 = "1";
    RADIANCE_MXFP4_W4A8_MIN_M = "0";
    RADIANCE_MXFP4_DECODE_MAX_M = "64";
    RADIANCE_MXFP4_TN4_MIN_M = "2048";
    RADIANCE_MXFP4_WPERM = "1";
    RADIANCE_MXFP4_DECODE_NT = "1";
  }
  // lib.optionalAttrs cfg.mxfp4W4A16 {
    RADIANCE_MXFP4_W4A16 = "1";
    RADIANCE_MXFP4_WPERM = "1";
  }
  // lib.optionalAttrs cfg.paroquant {
    RADIANCE_PQ_ROT_STREAM = "1";
    RADIANCE_PQ_ROT_STREAM2 = "1";
    RADIANCE_PQM_FUSED_TOKQ = "1";
    RADIANCE_PQM_SINGLE_LAUNCH = "1";
    RADIANCE_MXFP4_A_TILED_MIN_M = "513";
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
    # The entrypoint isolates fast-draft graphs; a stale ordinary-draft graph
    # would be reused against the packed W4 drafter weights and fail.
    VLLM_CACHE_ROOT = "${cfg.cacheDir}/vllm" + lib.optionalString cfg.fastDraft "-fast-draft";
    TORCHINDUCTOR_CACHE_DIR =
      "${cfg.cacheDir}/inductor" + lib.optionalString cfg.fastDraft "-fast-draft";
  };

  specEnv = lib.optionalAttrs (cfg.speculativeMethod == "dflash") {
    VLLM_USE_V2_MODEL_RUNNER = "1";
  };

  serviceEnv = rocmEnv // aiterEnv // radianceEnv // specEnv // cfg.extraEnv;

  # DFlash2 keeps the R4D target attention and runs the drafter on TRITON_ATTN;
  # MTP shares the target's backend as before.
  specConfig = builtins.toJSON (
    {
      method = cfg.speculativeMethod;
      num_speculative_tokens = cfg.speculativeTokens;
      attention_backend =
        if cfg.speculativeMethod == "dflash" then cfg.draftAttentionBackend else cfg.attentionBackend;
      disable_padded_drafter_batch = true;
    }
    // lib.optionalAttrs (cfg.draftModel != null) {
      model = cfg.draftModel;
    }
    // lib.optionalAttrs (cfg.draftTensorParallelSize != null) {
      draft_tensor_parallel_size = cfg.draftTensorParallelSize;
    }
    // lib.optionalAttrs (cfg.draftMaxModelLen != null) {
      max_model_len = cfg.draftMaxModelLen;
    }
  );

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
  ++ lib.optionals cfg.speculative [
    "--speculative-config ${lib.escapeShellArg specConfig}"
    "--no-async-scheduling"
  ]
  ++ lib.optionals (cfg.compilationConfig != null) [
    "--compilation-config ${lib.escapeShellArg (builtins.toJSON cfg.compilationConfig)}"
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
    assertions = [
      {
        assertion = !cfg.speculative || cfg.speculativeMethod != "dflash" || cfg.draftModel != null;
        message = "systemOptions.services.vllm: speculativeMethod = \"dflash\" needs draftModel.";
      }
    ];

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
