# HIP runtime (CLR) from pwilkin/rocm-systems `ilintar-experiments`: retained
# command lists on top of the ROCr vendor API, with packet-batch merging.
# The cmake invocation is install.sh's, with the SDK standing in for
# $rocm_root and the custom ROCr for $rocr_install.
{
  lib,
  stdenv,
  cmake,
  ninja,
  perl,
  python3,
  python3Packages,
  numactl,
  libffi,
  libxml2,
  libGL,
  libx11,
  zlib,
  zstd,
  rocmSdk,
  rocmSdkCc,
  rocrRuntime,
  src,
}:

stdenv.mkDerivation {
  pname = "hip-clr-strix-halo";
  version = "${rocmSdk.version}-${src.shortRev or "unknown"}";

  inherit src;
  sourceRoot = "${src.name or "source"}/projects/clr";

  nativeBuildInputs = [
    cmake
    ninja
    perl
    python3
    python3Packages.cppheaderparser
  ];
  buildInputs = [
    numactl
    libffi
    libxml2
    # ROCclr's HSA backend unconditionally looks for OpenGL/GLX headers
    # (install.sh gets them from libgl-dev); nothing links them for HIP.
    libGL
    libx11
    zlib
    zstd
    # ROCr before the SDK: both carry hsa/ headers and the compile picks them
    # up through the -isystem order of buildInputs (the fork's are newer).
    rocrRuntime
    rocmSdk
  ];

  # glibc's _FORTIFY_SOURCE inlines end up in the preprocessed header that
  # hip_prof_gen.py parses, and its C++ parser dies on them ("bad record").
  hardeningDisable = [
    "fortify"
    "fortify3"
  ];

  postPatch = ''
    patchShebangs --build hipamd/src
  '';

  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DCMAKE_POLICY_DEFAULT_CMP0072=NEW" # prefer GLVND OpenGL
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_PREFIX_PATH=${rocrRuntime};${rocmSdk}"
    "-DCLR_BUILD_HIP=ON"
    "-DCLR_BUILD_OCL=OFF"
    "-DHIP_PLATFORM=amd"
    "-DHIP_COMMON_DIR=${src}/projects/hip"
    "-DHIPCC_BIN_DIR=${rocmSdk}/bin"
    # The PCH generator runs $LLVM_ROOT/bin/clang on <hip/hip_runtime.h>,
    # which drags in libstdc++ headers: it has to be the wrapped clang.
    "-DLLVM_ROOT=${rocmSdkCc}/llvm"
    "-DClang_ROOT=${rocmSdkCc}/llvm"
    "-DROCM_PATH=${rocrRuntime}"
    "-Dhsa-runtime64_DIR=${rocrRuntime}/lib/cmake/hsa-runtime64"
    "-DROCCLR_ENABLE_HSA=ON"
    "-DROCCLR_ENABLE_PAL=OFF"
    "-DHIP_ENABLE_ROCPROFILER_REGISTER=ON"
    "-DUSE_PROF_API=ON"
    "-D__HIP_ENABLE_PCH=ON"
  ];

  postInstall = ''
    test -e $out/lib/libamdhip64.so.7
  '';

  meta = {
    description = "HIP runtime with retained PM4 command lists (pwilkin/rocm-systems ilintar-experiments)";
    homepage = "https://github.com/pwilkin/rocm-systems/tree/ilintar-experiments";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
