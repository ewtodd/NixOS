{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  gst_all_1,
  ipu7-camera-hal,
  libdrm,
  libva,
  apple-sdk_gstreamer,
}:

stdenv.mkDerivation {
  pname = "icamerasrc-${ipu7-camera-hal.ipuVersion}";
  version = "unstable-2024-11-29";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "icamerasrc";
    rev = "ee8526451ca1bb4957702de2f46138b63151f34c";
    hash = "sha256-GX67+A77/YQBwqqbBiDHrkiKb2CMAO5CJTwm1XyQOkg=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  preConfigure = ''
    export CHROME_SLIM_CAMHAL=ON
  '';

  configureFlags = [
    "--enable-gstdrmformat=yes"
  ];

  buildInputs = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    ipu7-camera-hal
    libdrm
    libva
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_gstreamer
  ];

  NIX_CFLAGS_COMPILE = [
    "-Wno-error"
    "-I${gst_all_1.gst-plugins-base.dev}/include/gstreamer-1.0"
  ];

  enableParallelBuilding = true;

  passthru = {
    inherit (ipu7-camera-hal) ipuVersion;
  };

  meta = {
    description = "GStreamer Plugin for MIPI camera support through the IPU7 on Intel platforms";
    homepage = "https://github.com/intel/icamerasrc/tree/icamerasrc_slim_api";
    license = lib.licenses.lgpl21Plus;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}
