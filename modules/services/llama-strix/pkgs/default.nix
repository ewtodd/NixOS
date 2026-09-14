# The Strix Halo inference stack that pwilkin/strix-halo install.sh assembles, as nix packages:
# rocmSdk (TheRock SDK) | rocmSdkCc (its nix-wrapped clang/hipcc) | rocrRuntime, hipClr (pwilkin/rocm-systems,
# retained PM4) | llamaCpp (strix-halo branch vs rocmSdk) | runtimeLibs (launcher LD_LIBRARY_PATH order).
{
  pkgs,
  llamaCppSrc,
  rocmSystemsSrc,
}:
let
  rocmSdk = pkgs.callPackage ./rocm-sdk-therock.nix { };
  rocmSdkCc = pkgs.callPackage ./rocm-sdk-cc.nix { inherit rocmSdk; };
  rocrRuntime = pkgs.callPackage ./rocr-runtime-strix-halo.nix {
    inherit rocmSdk;
    src = rocmSystemsSrc;
  };
  hipClr = pkgs.callPackage ./hip-clr-strix-halo.nix {
    inherit rocmSdk rocmSdkCc rocrRuntime;
    src = rocmSystemsSrc;
  };
  llamaCpp = pkgs.callPackage ./llama-cpp-strix-halo.nix {
    inherit rocmSdk rocmSdkCc;
    src = llamaCppSrc;
  };
  runtimeLibs = pkgs.lib.concatStringsSep ":" [
    "${hipClr}/lib"
    "${rocrRuntime}/lib"
    "${rocmSdk}/lib"
    "${rocmSdk}/lib/llvm/lib"
    "${llamaCpp}/lib"
  ];

  # install.sh refuses to finish unless libggml-hip resolves libamdhip64 and
  # libhsa-runtime64 through the custom prefixes; same check, at build time.
  runtimeCheck =
    pkgs.runCommand "llama-strix-runtime-check"
      {
        nativeBuildInputs = [ pkgs.glibc.bin ];
      }
      ''
        out_ldd=$(LD_LIBRARY_PATH=${runtimeLibs} ldd ${llamaCpp}/lib/libggml-hip.so)
        echo "$out_ldd"
        grep -F "${hipClr}/lib/libamdhip64.so" <<<"$out_ldd" \
          || { echo "libggml-hip does not resolve libamdhip64 through the custom HIP prefix"; exit 1; }
        grep -F "${rocrRuntime}/lib/libhsa-runtime64.so" <<<"$out_ldd" \
          || { echo "libggml-hip does not resolve libhsa-runtime64 through the custom ROCr prefix"; exit 1; }
        touch $out
      '';
in
{
  inherit
    rocmSdk
    rocmSdkCc
    rocrRuntime
    hipClr
    llamaCpp
    runtimeLibs
    runtimeCheck
    ;
}
