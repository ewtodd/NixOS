# llama-server from pwilkin's llama.cpp `strix-halo` branch, pinned to the
# revision and launcher configuration published at
# https://pwilkin.github.io/strix-halo/ (Qwen3.8-Next-Flash profile:
# 1204 t/s pp16384 on a Radeon 8060S). Runs on the Strix Halo iGPU of
# son-of-anton; the R9700s stay with vLLM.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.systemOptions.services.llamaStrix;

  stack = import ./pkgs {
    inherit pkgs;
    llamaCppSrc = inputs.llama-cpp-strix-halo;
    rocmSystemsSrc = inputs.rocm-systems-strix-halo;
  };
  inherit (stack) llamaCpp runtimeLibs runtimeCheck;

  # Env-gated kernels from the branch, verbatim from the flash-next launcher
  # that install.sh writes (qwen3.8-strix-halo-server). Every one of these
  # is a branch-only switch; upstream ignores them.
  branchKernelGates = {
    LLAMA_MMB = "1";
    LLAMA_MMB_MIN_T = "512";
    LLAMA_MMB_BF16W = "1";
    LLAMA_MMB_GLU = "1";
    LLAMA_MMB_TALL = "2";
    LLAMA_MMB_CACHE = "4";
    LLAMA_MMB_F32SPLIT = "2";
    LLAMA_MMB_HC16 = "2";
    LLAMA_MMB_SHADOW = "2";
    LLAMA_MMB_DOWN16 = "1";
    LLAMA_HC_CN_SHAPE = "1";
    LLAMA_HC_GATEMIX = "1";
    LLAMA_HC_MIX_FUSE = "1";
    LLAMA_HC_BLK16 = "1";
    LLAMA_HC_RES16 = "1";
    LLAMA_HC_PACK_DI = "1";
    LLAMA_NORM_GATED = "1";
    LLAMA_NORM_ROWS = "1";
    LLAMA_IDX_RELU_SUM = "1";
    LLAMA_PLE_CONV = "1";
    LLAMA_GDN_CONV = "1";
    LLAMA_QSA_SPARSE = "1";
    LLAMA_QSA_WHOLE_ATTN = "1";
    LLAMA_QSA_BLOCK_SELECTION = "1";
    LLAMA_QSA_COMPACT_METADATA = "1";
    LLAMA_QSA_DENSE_SHORTCUT = "1";
    LLAMA_QSA_DIRECT_INDICES = "1";
    LLAMA_QSA_PACK_KEYS = "1";
    LLAMA_QSA_PACK_VALUES = "1";
    LLAMA_QSA_QUERY_STRIP = "512";
    LLAMA_QSA_SCORE_BOUNDS = "1";
    LLAMA_QSA_NO_DENSE_MASK = "1";
    LLAMA_QSA_FA_V3 = "1";
    LLAMA_QSA_FUSE_EXPAND = "1";
    LLAMA_MTP_QSA = "1";
    LLAMA_MTP_QSA_MIN_T = "128";
  };

  # The launcher install.sh writes (llama-server-strix-halo), as environment:
  # the custom HIP/ROCr ahead of the SDK on the library path, and
  # ENABLE_RETAINED_PM4 choosing between retained-PM4 HIP graphs
  # (DEBUG_HIP_GRAPH_PM4=1) and no graphs at all (GGML_CUDA_DISABLE_GRAPHS=1).
  # Deliberately not copied: HSA_OVERRIDE_GFX_VERSION=11.5.1. It is a no-op on
  # a real gfx1151, and with this runtime it is applied to the two gfx1201
  # R9700s too, after which HIP refuses to initialize any device at all.
  runtimeEnv = {
    LD_LIBRARY_PATH = runtimeLibs;
    HIP_VISIBLE_DEVICES = cfg.devices;
    GGML_HIP_ENABLE_UNIFIED_MEMORY = "1";
    ENABLE_RETAINED_PM4 = if cfg.retainedPm4 then "1" else "0";
  }
  // (if cfg.retainedPm4 then { DEBUG_HIP_GRAPH_PM4 = "1"; } else { GGML_CUDA_DISABLE_GRAPHS = "1"; })
  // branchKernelGates
  // cfg.extraEnv;

  # --load-mode none + --lazy-mode on-direct keep the 27.5 GB per-layer
  # embedding table out of the resident set (rows are pread() on demand
  # instead of faulted in through an mmap that would hold a second copy of
  # every weight during load). -b/-ub 16384 is what makes the whole prompt
  # go through as one batch, which is where the prefill number comes from.
  serverArgs = [
    "-m ${cfg.model}"
    "--alias ${cfg.alias}"
    "-dev ROCm0"
    "-ngl 999"
    "-fa on"
    "-fit off"
    "--load-mode none"
    "--lazy-mode on-direct"
    "-ctk f16 -ctv f16"
    "-c ${toString cfg.ctxSize}"
    "-b ${toString cfg.batchSize}"
    "-ub ${toString cfg.ubatchSize}"
    "--parallel ${toString cfg.parallel}"
    "--jinja"
  ]
  ++ lib.optionals (cfg.ropeScaling != null) [ "--rope-scaling ${cfg.ropeScaling}" ]
  ++ lib.optionals (cfg.ropeScale != null) [ "--rope-scale ${toString cfg.ropeScale}" ]
  ++ lib.optionals (cfg.yarnOrigCtx != null) [ "--yarn-orig-ctx ${toString cfg.yarnOrigCtx}" ]
  ++ lib.optionals (cfg.ctxTrainOverride != null) [
    "--override-kv ${cfg.modelArch}.context_length=int:${toString cfg.ctxTrainOverride}"
  ]
  ++ lib.optionals (cfg.draftModel != null) [
    "--spec-type draft-mtp"
    "--spec-draft-model ${cfg.draftModel}"
    "--spec-draft-device ROCm0"
    "--spec-draft-ngl 99"
    "--spec-draft-n-max ${toString cfg.draftNMax}"
  ]
  ++ [
    "--host ${if cfg.lanExpose then "0.0.0.0" else "127.0.0.1"}"
    "--port ${toString cfg.port}"
  ]
  ++ cfg.extraFlags;
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    users.groups.llama-cache = { };

    systemd.services.llama-strix = {
      description = "llama.cpp strix-halo branch server (${cfg.alias})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = runtimeEnv;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${llamaCpp}/bin/llama-server ${lib.concatStringsSep " " serverArgs}";
        # Not run: referencing the check derivation makes the unit depend on
        # it, so a stack whose libggml-hip does not pick up the custom
        # HIP/ROCr fails at build time instead of silently running stock.
        ExecStartPre = "${pkgs.coreutils}/bin/test -e ${runtimeCheck}";
        Restart = "on-failure";
        RestartSec = 10;
        # Loading ~96 GB through on-demand pread() takes a while; do not let
        # a slow start be mistaken for a hang.
        TimeoutStartSec = "30min";
        User = cfg.user;
        SupplementaryGroups = [
          "video"
          "render"
          "llama-cache"
        ];
        LimitMEMLOCK = "infinity";
      };
    };
  };
}
