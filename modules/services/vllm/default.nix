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

  # Post-install source patches for gfx1201/RDNA4. Lives in the store, so a
  # change to it changes provisionStamp and forces a re-apply on deploy.
  patcher = ./apply-patches.py;

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
    # GFXLIBS selects the arch-specific ROCm library set: each wheel ships its own
    # librocblas with Tensile kernels for that arch ONLY, so they cannot share a path.
    GFXLIBS="${cfg.gfxLibs}"
    # The arch-specific library wheel MUST precede _rocm_sdk_devel: devel ships its
    # own librocblas.so built for gfx120X only, and whichever librocblas wins the
    # link order determines where Tensile kernels are searched for. gfx1151 also
    # uses a per-arch subdirectory (rocblas/library/gfx1151/) where gfx120X is flat.
    export LD_LIBRARY_PATH=${cfg.venvPath}/stublib:$SP/torch/lib:$SP/_rocm_sdk_libraries_''${GFXLIBS}/lib:$SP/_rocm_sdk_devel/lib:$SP/_rocm_sdk_core/lib:$SP/_rocm_sdk_core/lib/llvm/lib:$SP/_rocm_sdk_core/lib/rocm_sysdeps/lib:$SP/_rocm_sdk_core/lib/host-math/lib:''${LD_LIBRARY_PATH:-}
    export ROCBLAS_TENSILE_LIBPATH="$SP/_rocm_sdk_libraries_''${GFXLIBS}/lib/rocblas/library"
    # AITER: unified attention only (per the R9700 guide; other paths unvalidated on
    # gfx1201). NOTE: USE_AITER_UNIFIED_ATTENTION does NOT control backend selection.
    # vLLM force-overrides to ROCM_AITER_UNIFIED_ATTN when TURBOQUANT is rejected for
    # AttentionType.DECODER; to actually pin a backend use extraEnv.VLLM_ATTENTION_BACKEND.
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
    export GPU_MAX_HW_QUEUES=1 # required for spec decoding on RDNA4
    export NCCL_PROTO=Simple
    export HF_HOME=${cfg.modelCache}
    export HF_HUB_CACHE=${cfg.modelCache}
    ${lib.concatStringsSep "\n    " (
      lib.mapAttrsToList (n: v: "export ${n}=${lib.escapeShellArg v}") cfg.extraEnv
    )}
  '';

  # Anything that should invalidate the provisioned venv belongs in here.
  provisionStamp = builtins.hashString "sha256" (
    lib.concatStringsSep "\n" [
      cfg.vllmVersion
      cfg.flashAttnVersion
      cfg.rocmSdkVersion
      (lib.concatStringsSep " " cfg.gfxTargets)
      cfg.wheelIndex
      (toString patcher)
    ]
  );

  provisionScript = pkgs.writeScript "vllm-provision.sh" ''
        #!/usr/bin/env bash
        # Bring ${cfg.venvPath} in line with the declared configuration.
        #
        # Wheel installs only happen when the pinned vLLM version is not already
        # present, so the common path is offline: verify + apply source patches.
        set -euo pipefail
        source ${envScript}

        STAMP="$VENV/.nix-provision-stamp"
        WANT="${provisionStamp}"

        need_install=0
        [ -d "$VENV" ] || need_install=1
        [ -d "$SP/vllm-${cfg.vllmVersion}.dist-info" ] || need_install=1

        if [ "$need_install" = 1 ]; then
          echo "==> provisioning venv: vllm ${cfg.vllmVersion}, rocm-sdk ${cfg.rocmSdkVersion}"
          [ -d "$VENV" ] || python3.12 -m venv "$VENV"
          # shellcheck disable=SC1091
          source "$VENV/bin/activate"
          python -m pip install --upgrade pip setuptools wheel uv

          uv pip install \
            ${
              lib.concatMapStringsSep " " (c: "--find-links ${cfg.wheelIndex}/${c}/") [
                "vllm"
                "torch"
                "torchvision"
                "torchaudio"
                "triton"
                "triton-kernels"
                "amdsmi"
                "amd-aiter"
                "flash-attn"
              ]
            } \
            "vllm==${cfg.vllmVersion}" \
            "flash-attn==${cfg.flashAttnVersion}" \
            ${lib.escapeShellArg cfg.fastapiConstraint}
          uv pip install --no-deps torch-c-dlpack-ext || true

          # core + devel are arch-independent; take them from the first target's index.
          echo "==> rocm-sdk wheels for: ${lib.concatStringsSep " " cfg.gfxTargets}"
          uv pip install --no-deps \
            --index-url "${cfg.rocmIndex}/${builtins.head cfg.gfxTargets}/" \
            "rocm-sdk-core==${cfg.rocmSdkVersion}" \
            "rocm-sdk-devel==${cfg.rocmSdkVersion}"
          ${lib.concatMapStringsSep "\n      " (t: ''
            uv pip install --no-deps \
              --index-url "${cfg.rocmIndex}/${t}/" \
              "rocm-sdk-libraries-${t}==${cfg.rocmSdkVersion}"
          '') cfg.gfxTargets}

          python - <<'PY'
    import os, site, tarfile
    sp = next(p for p in site.getsitepackages() if p.endswith("site-packages"))
    tar = os.path.join(sp, "rocm_sdk_devel", "_devel.tar")
    if os.path.exists(tar):
        with tarfile.open(tar) as a:
            a.extractall(os.path.abspath(sp))
        os.remove(tar)
        print("extracted rocm_sdk_devel")
    else:
        print("devel tar already extracted")
    PY
        else
          # shellcheck disable=SC1091
          source "$VENV/bin/activate"
        fi

        echo "==> applying gfx1201 patches"
        python3 ${patcher} --site-packages "$SP"

        echo "==> verifying"
        python3 ${patcher} --site-packages "$SP" --check

        printf '%s\n' "$WANT" > "$STAMP"
        echo "==> venv provisioned"
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
      ${lib.optionalString cfg.languageModelOnly "--language-model-only"} \
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

    # Reconciles the venv with this configuration before vLLM starts. vllm.service
    # `Requires` it, so a failed or unapplied patch keeps the server down rather
    # than letting it come up in a state nobody declared.
    systemd.services.vllm-provision = {
      description = "Provision the vLLM venv (${cfg.model})";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      requiredBy = [ "vllm.service" ];
      before = [ "vllm.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = "users";
        ExecStart = "${fhsEnv}/bin/vllm-rocm-fhs -c 'bash ${provisionScript}'";
        TimeoutStartSec = "90min";
      };
    };

    systemd.services.vllm = {
      description = "vLLM inference server (${cfg.model})";
      after = [
        "network.target"
        "vllm-provision.service"
      ];
      requires = [ "vllm-provision.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        HIP_VISIBLE_DEVICES = cfg.devices;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = "users";
        ExecStart = "${fhsEnv}/bin/vllm-rocm-fhs -c 'bash ${serveScript}'";
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
