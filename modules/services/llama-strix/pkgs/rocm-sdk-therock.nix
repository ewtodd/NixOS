# AMD's ROCm Core SDK as shipped by TheRock (stable channel), per-family
# tarball for gfx1151. This is the "system ROCm SDK" that
# pwilkin/strix-halo install.sh builds the custom ROCr/HIP and llama.cpp
# against; 10.0.0 is the version the published Strix Halo numbers use.
#
# The dist is relocatable: every object links through $ORIGIN runpaths
# ($ORIGIN, $ORIGIN/rocm_sysdeps/lib, ...) and bundles its own
# libdrm/libnuma/zstd/... under lib/rocm_sysdeps. The only things it expects
# from the host are glibc, libstdc++ and libgcc_s. So on NixOS:
#   * libraries are left byte-for-byte untouched — patchelf (0.15 and 0.18)
#     mangles the program headers of several of the lld-linked ones
#     (libhipblaslt, librocblas, ...) and the loader segfaults on them;
#   * libstdc++/libgcc_s are symlinked into the dirs the runpaths already
#     search; glibc comes from the loader's own default path;
#   * executables get only their PT_INTERP pointed at the nix loader, and
#     each one is checked to still load afterwards.
{
  lib,
  stdenv,
  fetchurl,
  gcc-unwrapped,
  glibc,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocm-sdk-therock-gfx1151";
  version = "10.0.0";

  src = fetchurl {
    url = "https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-gfx1151-${finalAttrs.version}.tar.gz";
    hash = "sha256-T+q9ny2nI1LfN/bXFKVIR9P+kTwDQfviplQsEWQCS68=";
  };
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  # No stripping, no rpath shrinking: both rewrite the ELF files.
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a . $out/
    rm -f $out/env-vars
    # Debugger builds against five system Pythons and the ROCr test suite
    # carries its own hwloc; neither is needed here and neither resolves.
    rm -f $out/bin/rocgdb-py3.*
    rm -rf $out/lib/rocrtst

    # The two host libraries the dist does not bundle, placed where its
    # $ORIGIN runpaths already look (libraries: rocm_sysdeps/lib; the LLVM
    # tree: its own lib/).
    for d in lib/rocm_sysdeps/lib lib/llvm/lib; do
      ln -s ${gcc-unwrapped.lib}/lib/libstdc++.so.6 $out/$d/
      ln -s ${gcc-unwrapped.lib}/lib/libgcc_s.so.1 $out/$d/
    done

    # Executables: interpreter only.
    while IFS= read -r f; do
      isELF "$f" || continue
      patchelf --print-interpreter "$f" >/dev/null 2>&1 || continue
      patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} "$f"
    done < <(find $out -type f -perm -u+x -not -name '*.so*')

    # The tools the ROCr/CLR/llama.cpp builds and the service actually run
    # must still load after that (a patchelf-mangled binary fails here, not
    # later). Test programs, profilers, flang and hipify in the dist do not
    # resolve on their own runpaths (they expect /opt/rocm/lib on
    # LD_LIBRARY_PATH) and are not checked.
    for f in bin/hipcc bin/hipconfig bin/rocminfo \
             lib/llvm/bin/clang-23 lib/llvm/bin/lld lib/llvm/bin/llvm-mc \
             lib/llvm/bin/llvm-objcopy lib/llvm/bin/clang-offload-bundler \
             lib/llvm/bin/clang-offload-packager lib/llvm/bin/llvm-ar; do
      ${glibc}/lib/ld-linux-x86-64.so.2 --list "$out/$f" >/dev/null \
        || { echo "required tool does not load: $f" >&2; exit 1; }
    done
    runHook postInstall
  '';

  meta = {
    description = "ROCm Core SDK ${finalAttrs.version} (TheRock dist, gfx1151)";
    homepage = "https://github.com/ROCm/TheRock";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
