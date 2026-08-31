{
  lib,
  stdenv,
  gcc,
  gnumake,
  python3,
  rocmPackages,
  src,
}:

let
  inherit (rocmPackages)
    clr
    rocm-device-libs
    hipblas
    hipblas-common
    hipblaslt
    rocblas
    hipcub
    rocprim
    rocwmma
    ;

  archs = [ "gfx1151" ];
  offloadFlags = lib.concatMapStringsSep " " (a: "--offload-arch=${a}") archs;

  bitcode =
    if lib.pathExists "${rocm-device-libs}/amdgcn/bitcode" then
      "${rocm-device-libs}/amdgcn/bitcode"
    else
      "${rocm-device-libs}/lib/amdgcn/bitcode";

  includeFlags = lib.concatStringsSep " " (
    map (p: "-I${p}/include") [
      hipblas
      hipblas-common
      rocblas
      hipblaslt
      hipcub
      rocprim
      rocwmma
    ]
  );
  libDirs = lib.concatStringsSep " " (
    map (p: "-L${p}/lib") [
      hipblas
      hipblaslt
      rocblas
    ]
  );
  rpathFlags = lib.concatStringsSep " " (
    map (p: "-Wl,-rpath,${p}/lib") [
      hipblas
      hipblaslt
      rocblas
      clr
    ]
  );

  rocmCflags = lib.concatStringsSep " " [
    "-O3"
    "-ffast-math"
    "-g"
    "-fno-finite-math-only"
    "-pthread"
    "-D__HIP_PLATFORM_AMD__"
    "-Wno-unused-command-line-argument"
    "--rocm-device-lib-path=${bitcode}"
    offloadFlags
    includeFlags
  ];
  rocmLdlibs = lib.concatStringsSep " " [
    "-lm"
    "-pthread"
    libDirs
    rpathFlags
    "-lhipblas"
    "-lhipblaslt"
  ];

  coreObjs = lib.concatStringsSep " " [
    "ds4.o"
    "ds4_image.o"
    "ds4_distributed.o"
    "ds4_tp.o"
    "ds4_ssd.o"
    "ds4_rocm.o"
    "ds4_rocm_compat.o"
    "ds4_rocm_unavailable.o"
    "ds4_layer_pack.o"
  ];
in
stdenv.mkDerivation {
  pname = "ds4";
  version = "unstable";
  inherit src;

  nativeBuildInputs = [
    gcc
    gnumake
    python3
  ];

  buildInputs = [
    clr
    hipblas
    hipblaslt
    rocblas
  ];

  hardeningDisable = [ "fortify" ];

  buildPhase = ''
    export HOME=$TMPDIR
    export HIP_DEVICE_LIB_PATH=${bitcode}

    make strix-halo -j$NIX_BUILD_CORES \
      CC=gcc \
      HIPCC=${clr}/bin/hipcc \
      CORE_OBJS='${coreObjs}' \
      CFLAGS="-O3 -ffast-math -g -march=x86-64-v3 -Wall -Wextra -std=c99 -D_GNU_SOURCE -fno-finite-math-only -fPIC -DDS4_ROCM_BUILD" \
      ROCM_CFLAGS='${rocmCflags}' \
      ROCM_LDLIBS='${rocmLdlibs}' \
      DS4_LINK='${clr}/bin/hipcc ${rocmCflags}' \
      DS4_LINK_LIBS='${rocmLdlibs}'
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 ds4 ds4-server ds4-bench ds4-eval ds4-agent $out/bin/
    runHook postInstall
  '';

  meta = with lib; {
    description = "antirez/ds4 DwarfStar DeepSeek-V4 inference engine (ROCm)";
    homepage = "https://github.com/antirez/ds4";
    platforms = [ "x86_64-linux" ];
    license = licenses.mit;
  };
}
