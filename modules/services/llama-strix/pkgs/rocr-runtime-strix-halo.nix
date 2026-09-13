# ROCr (HSA runtime) from pwilkin/rocm-systems `ilintar-experiments`: the
# retained-PM4 command-list vendor API (hsa_ven_amd_graph_command_list_*).
# Built against the TheRock SDK exactly as install.sh does:
#   cmake -S projects/rocr-runtime -DCMAKE_PREFIX_PATH=$rocm_root -DBUILD_SHARED_LIBS=ON
{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  xxd,
  python3,
  elfutils,
  libdrm,
  numactl,
  zlib,
  zstd,
  rocmSdk,
  src,
}:

stdenv.mkDerivation {
  pname = "rocr-runtime-strix-halo";
  version = "1.21.0-${src.shortRev or "unknown"}";

  inherit src;
  sourceRoot = "${src.name or "source"}/projects/rocr-runtime";

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    xxd
    python3
  ];
  buildInputs = [
    elfutils
    libdrm
    numactl
    zlib
    zstd
    rocmSdk
  ];

  postPatch = ''
    patchShebangs --build \
      runtime/hsa-runtime/core/runtime/trap_handler \
      runtime/hsa-runtime/core/runtime/blit_shaders \
      runtime/hsa-runtime/image/blit_src
  '';

  cmakeBuildType = "Release";
  cmakeFlags = [
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_PREFIX_PATH=${rocmSdk}"
    "-DBUILD_SHARED_LIBS=ON"
  ];

  # Device-side blit/trap kernels are compiled by the SDK's clang; it finds
  # its device libs relative to itself, this is only belt and braces.
  env.HIP_DEVICE_LIB_PATH = "${rocmSdk}/lib/llvm/amdgcn/bitcode";

  postInstall = ''
    test -e $out/lib/libhsa-runtime64.so.1
    # libhsakmt.pc joins the pkg-config prefix variable with an already
    # absolute includedir ("''${prefix}//nix/store/...").
    substituteInPlace $out/lib/pkgconfig/libhsakmt.pc \
      --replace-fail "\''${prefix}/$out" "$out"
  '';

  meta = {
    description = "ROCr runtime with retained PM4 command lists (pwilkin/rocm-systems ilintar-experiments)";
    homepage = "https://github.com/pwilkin/rocm-systems/tree/ilintar-experiments";
    license = lib.licenses.ncsa;
    platforms = [ "x86_64-linux" ];
  };
}
