{
  lib,
  stdenv,
  fetchFromGitHub,

  # build
  cmake,
  pkg-config,

  # runtime
  expat,
  ipu7-camera-bins,
  jsoncpp,
  libtool,
  gst_all_1,
  libdrm,

  # Pick one of
  # - ipu7x (Lunar Lake)
  # - ipu75xa (Lunar Lake)
  ipuVersion ? "ipu7x",
}:
let
  ipuTarget =
    {
      "ipu7x" = "ipu_lnl";
      "ipu75xa" = "ipu_lnl";
    }
    .${ipuVersion};
in
stdenv.mkDerivation {
  pname = "${ipuVersion}-camera-hal";
  version = "unstable-2025-01-15";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "ipu7-camera-hal";
    rev = "431ff3f46ef821458d973390c8a88687637290c2";
    hash = "sha256-/bSH+NJgVQ4HoW6yDlZGyg9EqTs+t0S3ZibVwl7IWf4=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DBUILD_CAMHAL_ADAPTOR=ON"
    "-DBUILD_CAMHAL_PLUGIN=ON"
    "-DIPU_VERSIONS=${ipuVersion}"
    "-DUSE_STATIC_GRAPH=ON"
    "-DUSE_STATIC_GRAPH_AUTOGEN=ON"
    # Upstream sets CMAKE_CXX_STANDARD=11; force 17 to match jsoncpp 1.9.7's
    # ABI (it only ships the std::string_view overloads of Json::Value::isMember
    # / operator[] when JSONCPP_HAS_STRING_VIEW is set, which requires C++17).
    "-DCMAKE_CXX_STANDARD=17"
  ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error"
  ];

  enableParallelBuilding = true;

  buildInputs = [
    expat
    ipu7-camera-bins
    jsoncpp
    libtool
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libdrm
  ];

  postPatch = ''
    substituteInPlace src/platformdata/JsonParserBase.h \
      --replace-fail '<jsoncpp/json/json.h>' '<json/json.h>'

    # GCC 15 / libstdc++ no longer transitively includes <cstdint>; HalStream.h
    # uses uint32_t directly. Add the include after the file's #pragma once.
    # (Not in PR #479283; the PR predates the GCC bump.)
    substituteInPlace src/platformdata/gc/HalStream.h \
      --replace-fail '#pragma once' $'#pragma once\n\n#include <cstdint>'

    # Bump from C++11 to C++17 so JSONCPP_HAS_STRING_VIEW takes effect; without
    # it the headers expose Json::Value::isMember(const char*) overloads that
    # libjsoncpp 1.9.7 does not export, breaking the link of ipu7x.so.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'set (CMAKE_CXX_STANDARD 11)' 'set (CMAKE_CXX_STANDARD 17)'
  '';

  postInstall = ''
    mkdir -p $out/include/${ipuTarget}/
    cp -r $src/include $out/include/${ipuTarget}/libcamhal
  '';

  postFixup = ''
    for lib in $out/lib/*.so; do
      patchelf --add-rpath "${ipu7-camera-bins}/lib" $lib
    done
  '';

  passthru = {
    inherit ipuVersion ipuTarget;
  };

  meta = with lib; {
    description = "HAL for processing of images in userspace";
    homepage = "https://github.com/intel/ipu7-camera-hal";
    license = licenses.asl20;
    maintainers = [ lib.maintainers.pseudocc ];
    platforms = [ "x86_64-linux" ];
  };
}
