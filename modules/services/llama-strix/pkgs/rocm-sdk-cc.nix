# The TheRock SDK's clang/hipcc, made usable inside nix builds.
#
# The SDK's clang has no idea where NixOS keeps libstdc++ and glibc headers
# (there is no /usr/include), so every host-side or `-x hip` compile fails on
# <cstdlib>. This mirrors what nixpkgs' cc-wrapper does for its own ROCm
# clang: point at the gcc toolchain, add glibc headers *after* libstdc++'s
# (`-idirafter`, so `#include_next` still works), and link against the nix
# glibc/libgcc with the right dynamic loader.
#
# Output layout:
#   bin/{clang,clang++,hipcc}  wrappers
#   llvm/                      mirror of the SDK's lib/llvm with bin/clang and
#                              bin/clang++ replaced by the wrappers, so a
#                              build that wants an LLVM_ROOT (CLR's PCH step)
#                              can be pointed here.
{
  lib,
  stdenv,
  runCommand,
  runtimeShell,
  xorg,
  rocmSdk,
  gcc-unwrapped,
  glibc,
}:

let
  triple = stdenv.hostPlatform.config;
  toolchainFlags = lib.concatStringsSep " " [
    "--gcc-install-dir=${gcc-unwrapped}/lib/gcc/${triple}/${gcc-unwrapped.version}"
    "-idirafter ${lib.getDev glibc}/include"
    "-B${glibc}/lib"
    "-B${gcc-unwrapped.lib}/lib"
    "-L${glibc}/lib"
    "-L${gcc-unwrapped.lib}/lib"
    "-Wl,-rpath,${gcc-unwrapped.lib}/lib"
    "-Wl,-rpath,${rocmSdk}/lib"
    "-Wl,-dynamic-linker,${stdenv.cc.bintools.dynamicLinker}"
  ];
  llvmBin = "${rocmSdk}/lib/llvm/bin";

  # `-cc1` / `-cc1as` invocations (CLR's PCH generator calls the frontend
  # directly) take no driver flags; pass those through untouched.
  clangWrapper = ''
    #!${runtimeShell}
    case "$1" in
      -cc1|-cc1as) exec -a "$0" ${llvmBin}/clang-23 "$@" ;;
    esac
    exec -a "$0" ${llvmBin}/clang-23 "$@" ${toolchainFlags}
  '';
in
runCommand "rocm-sdk-cc-${rocmSdk.version}"
  {
    nativeBuildInputs = [ xorg.lndir ];
    passthru = {
      inherit rocmSdk;
    };
  }
  ''
    mkdir -p $out/bin $out/llvm
    # Real directories, symlinked files: consumers walk `..` from
    # llvm/lib/cmake/llvm back up to this tree (CLR's PCH step does), and a
    # symlinked lib/ would send them into the SDK and past the wrappers.
    lndir -silent ${rocmSdk}/lib/llvm $out/llvm
    rm "$out/llvm/bin/clang" "$out/llvm/bin/clang++"

    cat > $out/llvm/bin/clang <<'WRAP'
    ${clangWrapper}
    WRAP
    cp $out/llvm/bin/clang $out/llvm/bin/clang++
    cat > $out/bin/hipcc <<WRAP
    #!${runtimeShell}
    export HIP_CLANG_PATH=$out/llvm/bin
    exec ${rocmSdk}/bin/hipcc "\$@"
    WRAP
    chmod +x $out/llvm/bin/clang $out/llvm/bin/clang++ $out/bin/hipcc
    ln -s $out/llvm/bin/clang $out/bin/clang
    ln -s $out/llvm/bin/clang++ $out/bin/clang++
  ''
