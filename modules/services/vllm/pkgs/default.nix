{
  pkgs,
  r4dSrc,
  radianceSrc,
}:
let
  inherit (pkgs) lib;
  gfxArch = "gfx1201";

  rocmSdk = pkgs.callPackage ../../../pkgs/rocm-sdk-therock.nix { family = "gfx120X-all"; };
  rocmSdkCc = pkgs.callPackage ../../../pkgs/rocm-sdk-cc.nix { inherit rocmSdk; };

  rocmPackages = {
    clr = rocmSdk // {
      icd = rocmSdk;
      gpuTargets = [ gfxArch ];
      localGpuTargets = [ gfxArch ];
    };
    hipcc = rocmSdkCc;
    llvm = {
      openmp = rocmSdk;
      clang = rocmSdkCc;
      lld = rocmSdk;
    };
    composable_kernel = rocmSdk // {
      anyMfmaTarget = false;
      composable_kernel_src = rocmSdk;
    };
    rocprofiler-sdk = rocmSdk // {
      dev = rocmSdk;
    };
  }
  // lib.genAttrs [
    "rocm-core"
    "rccl"
    "miopen"
    "miopen-hip"
    "aotriton"
    "rocrand"
    "rocblas"
    "rocsparse"
    "hipsparse"
    "hipsparselt"
    "rocthrust"
    "rocprim"
    "hipcub"
    "roctracer"
    "rocfft"
    "rocsolver"
    "hipfft"
    "hiprand"
    "hipsolver"
    "hipblas-common"
    "hipblas"
    "hipblaslt"
    "rocminfo"
    "rocm-comgr"
    "rocm-device-libs"
    "rocm-runtime"
    "rocm-smi"
    "hipify"
    "amdsmi"
    "rocshmem"
  ] (_: rocmSdk);

  hipEnv = {
    ROCM_PATH = "${rocmSdk}";
    HIP_PATH = "${rocmSdk}";
    HIP_CLANG_PATH = "${rocmSdkCc}/llvm/bin";
    HIP_DEVICE_LIB_PATH = "${rocmSdk}/lib/llvm/amdgcn/bitcode";
  };

  radiancePatches =
    pkgs.runCommand "radiance-patches"
      {
        src = radianceSrc;
      }
      ''
        mkdir -p $out
        cp $src/patch_*.py $src/install_radiance_hooks.py $src/_patchlib.py $out/
        chmod u+w $out/*.py
        for f in $out/*.py; do
          substituteInPlace $f --replace-quiet \
            'sysconfig.get_paths()["purelib"]' \
            '__import__("os").environ["RADIANCE_SP"]'
        done
        substituteInPlace $out/_patchlib.py --replace-fail \
          'raise SystemExit(f"  FAIL  {label}: {path} missing")' \
          'print(f"  SKIP  {label}: {path} not in this package"); return'
      '';

  applyRadiancePatches = names: ''
    export RADIANCE_SP=$out/${python.sitePackages}
    chmod -R u+w $RADIANCE_SP
    pushd ${radiancePatches} >/dev/null
    for p in ${lib.concatStringsSep " " names}; do
      echo "== radiance: $p =="
      python $p.py
    done
    popd >/dev/null
  '';

  aiterPatches = [
    "patch_unified_attention_lds"
    "patch_radiance_dispatch"
  ];

  vllmPatches = [
    "patch_gfx1201"
    "patch_radiance_dispatch"
    "patch_skinny_gemm"
    "patch_gdn_wmma"
    "patch_gdn_aiter_prefill"
    "patch_preshuffle"
    "install_radiance_hooks"
    "patch_unpad"
    "patch_mtp_mm_mask"
    "patch_mtp_loopbreak"
    "patch_qwen3_toolparse"
    "patch_from_json_filter"
    "patch_conv1d_blockn"
    "patch_r4d"
    "patch_gdn_metadata"
    "patch_gdn_shared_build"
    "patch_topk_triton_rows"
    "patch_topk_composite"
    "patch_rocm_cudagraph_current_stream"
    "patch_ar_maxbytes"
    "patch_ar_geometry"
    "patch_kv_group_size"
    "patch_gdn_merge_inproj"
    "patch_dynwidth"
    "patch_verify_head"
    "patch_xgrammar_spec_termination"
    "patch_xgrammar_spec_reasoning"
    "patch_parser_shared_engine"
    "patch_qwen_open_object_schema"
  ];

  tritonLlvm = pkgs.triton-llvm.overrideAttrs (old: {
    cmakeFlags = old.cmakeFlags ++ [ (lib.cmakeBool "BUILD_SHARED_LIBS" false) ];
  });

  python = pkgs.python3.override {
    packageOverrides = self: super: {
      triton = super.triton.override { llvm = tritonLlvm; };

      torch =
        (super.torch.override {
          rocmSupport = true;
          cudaSupport = false;
          inherit rocmPackages;
          gpuTargets = [ gfxArch ];
          effectiveMagma = null;
        }).overrideAttrs
          (old: {
            buildInputs = old.buildInputs ++ [ pkgs.libdrm ];
            env =
              old.env
              // hipEnv
              // {
                USE_MAGMA = "0";
                USE_FLASH_ATTENTION = "0";
                USE_MEM_EFF_ATTENTION = "0";
              };
          });

      torchcodec = super.torchcodec.overridePythonAttrs (old: {
        # torch's LoadHIP falls back to ${ROCM_PATH}/lib/llvm/bin/clang++ when HIP_CLANG_PATH
        # is unset: unwrapped clang, no libstdc++ headers, compiler ABI check dies on <cstdlib>.
        env = old.env // {
          HIP_CLANG_PATH = "${rocmSdkCc}/llvm/bin";
        };
        # rocm_smi-config.cmake does pkg_check_modules(libdrm REQUIRED); the raw SDK propagates
        # nothing, so the .pc must come from nixpkgs — same fix as the torch buildInputs above.
        buildInputs = old.buildInputs ++ [ pkgs.libdrm ];
      });

      backrefs = super.backrefs.overridePythonAttrs (_: {
        doCheck = false;
      });
      einops = super.einops.overridePythonAttrs (_: {
        doCheck = false;
      });
      interegular = super.interegular.overridePythonAttrs (_: {
        doCheck = false;
      });
      devtools = super.devtools.overridePythonAttrs (_: {
        doCheck = false;
      });
      hypercorn = super.hypercorn.overridePythonAttrs (_: {
        doCheck = false;
      });
      inline-snapshot = super.inline-snapshot.overridePythonAttrs (_: {
        doCheck = false;
      });
      outlines = super.outlines.overridePythonAttrs (_: {
        doCheck = false;
      });
      mistral-common = super.mistral-common.overridePythonAttrs (old: {
        pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "numpy" ];
      });
      xgrammar = super.xgrammar.overridePythonAttrs (old: rec {
        version = "0.2.3";
        src = pkgs.fetchFromGitHub {
          owner = "mlc-ai";
          repo = "xgrammar";
          tag = "v${version}";
          fetchSubmodules = true;
          hash = "sha256-bznSz1fOCCGFR3NsuXm5eWo7EXrvBrFavEllC5+vDHM=";
        };
        patches = [ ];
        build-system = [
          self.cmake
          self.ninja
          self.scikit-build-core
          self.apache-tvm-ffi
        ];
        dependencies = old.dependencies ++ [ self.apache-tvm-ffi ];
        doCheck = false;
      });
      transformers = super.transformers.overridePythonAttrs (old: {
        postInstall = (old.postInstall or "") + applyRadiancePatches [ "patch_from_json_filter" ];
      });

      amdsmi = self.buildPythonPackage {
        pname = "amdsmi";
        version = "27.0.0+6b0e43f3";
        pyproject = true;
        src = "${rocmSdk}/share/amd_smi";
        build-system = [ self.setuptools ];
        postPatch = ''
          rm -f amdsmi/libamd_smi.so
          substituteInPlace amdsmi/amdsmi_wrapper.py --replace-fail \
            'possible_locations.append("libamd_smi.so")' \
            'possible_locations.append("${rocmSdk}/lib/libamd_smi.so")'
        '';
        pythonImportsCheck = [ "amdsmi" ];
      };

      amd-aiter = (super.amd-aiter.override { inherit rocmPackages; }).overrideAttrs (old: {
        version = "0.1.20";
        src = pkgs.fetchFromGitHub {
          owner = "ROCm";
          repo = "aiter";
          rev = "fc2e5d57fb5b8ad8e7e23f7103071dde798ea618";
          hash = "sha256-aL7uEkTvJ19mAp69lWC7VmHgVejr+7kfPta4FphSf1g=";
          fetchSubmodules = true;
        };
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail '"flydsl==0.3.1"' ""

          substituteInPlace csrc/cpp_itfs/utils.py \
            --replace-fail \
              'commit_id = get_git_commit_id_short()' \
              'commit_id = "0.1.20"'

          substituteInPlace aiter/jit/utils/cpp_extension.py \
            --replace-fail \
              'paths.append(rocm_include)' \
              'paths.append(rocm_include); paths.extend(os.environ.get("NIX_AITER_ROCM_INCL", "${rocmSdk}/include:${lib.getDev self.pybind11}/include").split(":"))'

          substituteInPlace setup.py \
            --replace-fail \
              '    prepare_packaging()' \
              '    if not os.path.exists("aiter_meta"): prepare_packaging()' \
            --replace-fail \
              'if os.path.exists("aiter_meta") and os.path.isdir("aiter_meta"):' \
              'if False:'
        '';
        pythonRemoveDeps = [ "flydsl" ];
        env = old.env // hipEnv;
        postInstall = (old.postInstall or "") + applyRadiancePatches aiterPatches;
      });

      vllm =
        (super.vllm.override {
          inherit rocmPackages;
          gpuTargets = [ gfxArch ];
          xformers = null;
        }).overrideAttrs
          (
            finalAttrs: old: {
              version = "0.28.0";
              src = pkgs.fetchFromGitHub {
                owner = "vllm-project";
                repo = "vllm";
                rev = "2cf0a6915ce544dc493a0990f2ea38d81601128a";
                hash = "sha256-Ia5SB9bQ+Vxkc5wBwY7HxQo6rqYFpWlVxeQyyP55dMg=";
              };
              patches = lib.filter (p: baseNameOf p != "0005-drop-intel-reqs.patch") old.patches;
              propagatedBuildInputs = lib.filter (
                d: d != null && (d.pname or "") != "torchaudio"
              ) old.propagatedBuildInputs;
              pythonRemoveDeps = old.pythonRemoveDeps ++ [ "torchaudio" ];
              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit (finalAttrs)
                  pname
                  version
                  src
                  cargoRoot
                  ;
                hash = "sha256-CLvLAkejYfrnrPXJ78xh2mgCyRg7F56Um1LPnJtj7iw=";
              };
              env = old.env // hipEnv;
              # vllm's CMake hits the same rocm_smi → pkg_check_modules(libdrm REQUIRED) chain
              # through find_package(Torch); see the torchcodec override.
              buildInputs = old.buildInputs ++ [ pkgs.libdrm ];
              postInstall =
                (old.postInstall or "")
                + ''
                  SP=$out/${python.sitePackages}
                  chmod -R u+w $SP
                  cp ${radianceSrc}/radiance_*.py ${radianceSrc}/radiance_amdsmi.pth $SP/
                  cp -f ${radianceSrc}/fp8-configs/* $SP/vllm/model_executor/layers/quantization/utils/configs/
                  cp -f ${radianceSrc}/moe-configs/* $SP/vllm/model_executor/layers/fused_moe/configs/
                  mkdir -p $out/share/vllm-radiance
                  cp ${radianceSrc}/qwen3.8-enhanced.jinja ${radianceSrc}/qwen3.6-enhanced.jinja $out/share/vllm-radiance/
                ''
                + applyRadiancePatches vllmPatches;
            }
          );
    };
  };

  libr4d = pkgs.callPackage ./libr4d.nix {
    inherit
      python
      rocmSdk
      rocmSdkCc
      gfxArch
      ;
    src = r4dSrc;
    patches = [ "${radianceSrc}/r4d_radiance_extras.patch" ];
  };

  pythonEnv = python.withPackages (ps: [
    ps.vllm
    (ps.toPythonModule libr4d)
  ]);

  runtimeLibs = "${rocmSdk}/lib";
in
{
  inherit
    rocmSdk
    rocmSdkCc
    rocmPackages
    python
    libr4d
    pythonEnv
    runtimeLibs
    gfxArch
    ;
  torch = python.pkgs.torch;
  aiter = python.pkgs.amd-aiter;
  vllm = python.pkgs.vllm;
}
