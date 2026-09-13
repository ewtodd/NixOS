# llama.cpp from pwilkin's `strix-halo` integration branch, built for the
# Strix Halo iGPU (gfx1151) against the TheRock ROCm SDK — the same
# "system ROCm" install.sh compiles against — and configured with that
# script's cmake flags.
#
# The branch ships upstream's .devops/nix/package.nix, so this is a thin
# callPackage wrapper around it: a synthetic `rocmPackages` set points every
# ROCm dependency at the single SDK prefix, and the compiler at the wrapped
# SDK clang.
{
  lib,
  callPackage,
  rocmSdk,
  rocmSdkCc,
  src,
  llamaVersion ? "strix-halo-${src.shortRev or "unknown"}",
}:
let
  rocmPackages = {
    clr = rocmSdk;
    hipblas = rocmSdk;
    rocblas = rocmSdk;
    rocm-device-libs = rocmSdk; # package.nix wants ${...}/amdgcn/bitcode
    llvm.clang = rocmSdkCc;
  };

  base = callPackage "${src}/.devops/nix/package.nix" {
    inherit llamaVersion rocmPackages;
    useRocm = true;
    useBlas = false;
    useCuda = false;
    useVulkan = false;
    rocmGpuTargets = "gfx1151";
    # The web UI is an npm build (importNpmLock) we do not need for an API
    # server; skipping it keeps the build off the branch's package-lock.
    useWebUi = false;
  };
in
base.overrideAttrs (
  finalAttrs: oldAttrs: {
    # Even with useWebUi = false the upstream derivation carries `webui` as
    # an attribute, which would still make nix build it. Drop it.
    webui = null;

    cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
      "-DGPU_TARGETS=gfx1151"
      (lib.cmakeBool "GGML_HIP_GRAPHS" true)
      (lib.cmakeBool "GGML_HIP_NO_VMM" true)
      (lib.cmakeBool "GGML_HIP_MMQ_MFMA" true)
      (lib.cmakeBool "GGML_HIP_RCCL" false)
      (lib.cmakeBool "GGML_CUDA_FA" true)
      (lib.cmakeBool "GGML_CUDA_FA_ALL_QUANTS" false)
      (lib.cmakeBool "GGML_VULKAN" false)
      (lib.cmakeBool "LLAMA_BUILD_TESTS" false)
      (lib.cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    ];

    # install.sh: PATH="$rocm_root/bin:$PATH" ROCM_PATH="$rocm_root"
    env = (oldAttrs.env or { }) // {
      ROCM_PATH = "${rocmSdk}";
      HIP_DEVICE_LIB_PATH = "${rocmSdk}/lib/llvm/amdgcn/bitcode";
    };

    # libggml-hip is linked by the SDK's clang, not nix's ld wrapper, so it
    # misses the $out/lib self-runpath every other library here gets and
    # cannot find its sibling libggml-base. Add it back.
    postFixup = (oldAttrs.postFixup or "") + ''
      for f in $out/lib/libggml-hip.so*; do
        [ -L "$f" ] || patchelf --add-rpath $out/lib "$f"
      done
    '';

    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $out/nix-support
      echo "${llamaVersion}" > $out/nix-support/llama-cpp-version
      echo "-DGPU_TARGETS=gfx1151" > $out/nix-support/supported-hardware
      echo "${rocmSdk.version}" > $out/nix-support/rocm-sdk-version
    '';

    passthru = (oldAttrs.passthru or { }) // {
      inherit rocmSdk rocmSdkCc;
    };

    meta = (oldAttrs.meta or { }) // {
      description = "llama.cpp, pwilkin strix-halo branch (ROCm ${rocmSdk.version}, gfx1151)";
      homepage = "https://github.com/pwilkin/llama.cpp/tree/strix-halo";
      platforms = [ "x86_64-linux" ];
    };
  }
)
