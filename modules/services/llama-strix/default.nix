# llama-server from pwilkin's llama.cpp `strix-halo` branch, pinned per https://pwilkin.github.io/strix-halo/
# (Qwen3.8-Next-Flash profile: 1204 t/s pp16384 on a Radeon 8060S). Runs on son-of-anton's Strix Halo iGPU.
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

  # vLLM's warmup claims host memory for ~20-60 s; wait for its /health before
  # loading, bounded so a dead vLLM never blocks llama (see the HSA faults 2026-09).
  vllmCfg = config.systemOptions.services.vllm;
  vllmHealthWait = pkgs.writeShellScript "llama-strix-wait-vllm" ''
    set -u
    url="http://127.0.0.1:${toString vllmCfg.port}/health"
    deadline=$(( $(${pkgs.coreutils}/bin/date +%s) + 300 ))
    while true; do
      if ${pkgs.curl}/bin/curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
        echo "vLLM /health is up; starting llama-strix"
        exit 0
      fi
      if [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$deadline" ]; then
        echo "vLLM /health not up after 300s; starting llama-strix anyway" >&2
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 5
    done
  '';

  # Runtime env from the launcher install.sh writes (llama-server-strix-halo):
  # custom HIP/ROCr ahead of the SDK, and ENABLE_RETAINED_PM4 choosing
  # retained-PM4 HIP graphs vs no graphs. The per-kernel LLAMA_* gates that
  # used to sit here were compiled into the branch in ac1ebb4e (2026-09-13)
  # and install.sh no longer exports them. Deliberately NOT copied:
  # HSA_OVERRIDE_GFX_VERSION=11.5.1 -- a no-op on gfx1151, but it reaches the gfx1201 R9700s too and
  # HIP then refuses to initialize any device.
  runtimeEnv = {
    LD_LIBRARY_PATH = runtimeLibs;
    HIP_VISIBLE_DEVICES = cfg.devices;
    GGML_HIP_ENABLE_UNIFIED_MEMORY = "1";
    ENABLE_RETAINED_PM4 = if cfg.retainedPm4 then "1" else "0";
  }
  // (if cfg.retainedPm4 then { DEBUG_HIP_GRAPH_PM4 = "1"; } else { GGML_CUDA_DISABLE_GRAPHS = "1"; })
  // cfg.extraEnv;
  # --load-mode none + --lazy-mode on-direct keep the 27.5 GB embedding table out of the resident set
  # (pread on demand, no mmap double-copy of every weight during load). -b/-ub 16384 sends the whole
  # prompt as one batch -- the source of the prefill number.
  serverArgs = [
    "-m ${cfg.model}"
    "--alias ${cfg.alias}"
    "-dev ROCm0"
    "-ngl 999"
    "-fa on"
    "-fit off"
    "--load-mode none"
    "--lazy-mode on-direct"
    "--cache-type-k ${cfg.kQuant}"
    "--cache-type-v ${cfg.vQuant}"
    "-c ${toString cfg.ctxSize}"
    "-b ${toString cfg.batchSize}"
    "-ub ${toString cfg.ubatchSize}"
    "--parallel ${toString cfg.parallel}"
  ]
  ++ lib.optionals cfg.kvUnified [ "--kv-unified" ]
  ++ [
    "--jinja"
  ]
  ++ lib.optionals (cfg.mmproj != null) [
    "--mmproj ${cfg.mmproj}"
    "--mmproj-device ROCm0"
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
      after = [ "network.target" ] ++ lib.optionals vllmCfg.enable [ "vllm.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = runtimeEnv;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${llamaCpp}/bin/llama-server ${lib.concatStringsSep " " serverArgs}";
        # Not run: referencing the check derivation makes the unit depend on
        # it, so a stack whose libggml-hip does not pick up the custom
        # HIP/ROCr fails at build time instead of silently running stock.
        ExecStartPre = [
          "${pkgs.coreutils}/bin/test -e ${runtimeCheck}"
        ]
        ++ lib.optionals vllmCfg.enable [ "${vllmHealthWait}" ];
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
