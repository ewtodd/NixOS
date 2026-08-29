{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.vllm;

  fhsEnv = pkgs.buildFHSEnv {
    name = "vllm-rocm-fhs";
    targetPkgs =
      p: with p; [
        python312
        python312Packages.pip
        python312Packages.virtualenv
        uv
        gcc
        binutils
        git
        curl
        cacert
        which
        file
        stdenv.cc.cc.lib
        libdrm
        elfutils
        numactl
        openmpi
        libjpeg_turbo
        zlib
        zstd
        ncurses
        libxml2
        libffi
        openssl
        sqlite
        xz
        bzip2
        rocmPackages.rocm-smi
        pciutils
        kmod
      ];
    multiPkgs =
      p: with p; [
        stdenv.cc.cc.lib
        zlib
      ];
    runScript = "bash";
    profile = ''
      export VLLM_TARGET_DEVICE=rocm
      unset HSA_OVERRIDE_GFX_VERSION
    '';
  };

  envScript = pkgs.writeScript "vllm-env.sh" ''
    export VENV=${cfg.venvPath}
    export SP=$VENV/lib/python3.12/site-packages
    export VLLM_TARGET_DEVICE=rocm
    export ROCM_PATH=$SP/_rocm_sdk_devel
    export ROCM_HOME=$SP/_rocm_sdk_devel
    export HIP_PATH=$SP/_rocm_sdk_devel
    export HIP_HOME=$SP/_rocm_sdk_devel
    export HIP_DEVICE_LIB_PATH=$SP/_rocm_sdk_devel/lib/llvm/amdgcn/bitcode
    export DEVICE_LIB_PATH=$SP/_rocm_sdk_devel/lib/llvm/amdgcn/bitcode
    export CPATH=$SP/_rocm_sdk_devel/include:''${CPATH:-}
    export LIBRARY_PATH=$SP/_rocm_sdk_devel/lib:''${LIBRARY_PATH:-}
    export PYTHONPATH=$SP/_rocm_sdk_core/share/amd_smi
    GFXLIBS="${cfg.gfxLibs}"
    export LD_LIBRARY_PATH=${cfg.venvPath}/stublib:$SP/torch/lib:$SP/_rocm_sdk_libraries_''${GFXLIBS}/lib:$SP/_rocm_sdk_devel/lib:$SP/_rocm_sdk_core/lib:$SP/_rocm_sdk_core/lib/llvm/lib:$SP/_rocm_sdk_core/lib/rocm_sysdeps/lib:$SP/_rocm_sdk_core/lib/host-math/lib:''${LD_LIBRARY_PATH:-}
    export ROCBLAS_TENSILE_LIBPATH="$SP/_rocm_sdk_libraries_''${GFXLIBS}/lib/rocblas/library"
    export VLLM_ROCM_USE_AITER=1
    export VLLM_ROCM_USE_AITER_MHA=0
    export VLLM_ROCM_USE_AITER_MLA=0
    export VLLM_ROCM_USE_AITER_MOE=0
    export VLLM_ROCM_USE_AITER_LINEAR=0
    export VLLM_ROCM_USE_AITER_FP8BMM=0
    export VLLM_ROCM_USE_AITER_FP4BMM=0
    export VLLM_ROCM_USE_AITER_TRITON_GEMM=0
    export VLLM_ROCM_USE_AITER_RMSNORM=0
    export VLLM_ROCM_USE_AITER_UNIFIED_ATTENTION=1
    export GPU_MAX_HW_QUEUES=1
    export NCCL_PROTO=Simple
    export HF_HOME=${cfg.modelCache}
    export HF_HUB_CACHE=${cfg.modelCache}
  '';

  specArg =
    if cfg.mtp then
      "--speculative-config '{\"method\":\"mtp\",\"num_speculative_tokens\":${toString cfg.mtpTokens}}'"
    else
      "";

  serveScript = pkgs.writeScript "vllm-serve.sh" ''
    #!/usr/bin/env bash
    set -uo pipefail
    source ${envScript}
    source "$VENV/bin/activate"
    exec vllm serve ${cfg.model} \
      --tensor-parallel-size ${toString cfg.tensorParallelSize} \
      --max-model-len ${toString cfg.maxModelLen} \
      --kv-cache-dtype ${cfg.kvCacheDtype} \
      --max-num-seqs ${toString cfg.maxNumSeqs} \
      --gpu-memory-utilization ${toString cfg.gpuMemoryUtilization} \
      --host 0.0.0.0 --port ${toString cfg.port} \
      --language-model-only \
      ${
        lib.optionalString (
          cfg.toolCallParser != null
        ) "--enable-auto-tool-choice --tool-call-parser ${cfg.toolCallParser}"
      } \
      ${lib.optionalString (cfg.reasoningParser != null) "--reasoning-parser ${cfg.reasoningParser}"} \
      ${lib.optionalString cfg.enforceEager "--enforce-eager"} \
      ${specArg} \
      ${lib.concatStringsSep " " cfg.extraFlags}
  '';
in
{
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.lanExpose [ cfg.port ];

    systemd.services.vllm = {
      description = "vLLM inference server (${cfg.model})";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HIP_VISIBLE_DEVICES = cfg.devices;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${fhsEnv}/bin/vllm-rocm-fhs -c 'bash ${serveScript}'";
        Restart = "on-failure";
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
