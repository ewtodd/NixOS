{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  libgcc,
  libglvnd,
  openssl,
  libgpg-error,
  libz,
  freetype,
  fontconfig,
  gmp,
  e2fsprogs,
  libdrm,
  vtkWithQt6,
}:

stdenv.mkDerivation rec {
  name = "lise-app";
  version = "17.17.20";

  src = fetchurl {
    url = "https://lise.frib.msu.edu/download/Linux/lise-app_v17.17.20-2_all.deb";
    sha256 = "sha256-9sCqhXOqOvQ7rxsBlNHtZ8bnHhjuMaVmyPUEEoL1omI=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc
    libgcc
    libglvnd
    openssl
    libgpg-error
    libz
    freetype
    fontconfig
    gmp
    e2fsprogs
    libdrm
    vtkWithQt6
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  preBuild = ''
    addAutoPatchelfSearchPath usr/lib/lise-app/lib 
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
  '';

  postPatch = ''
    # Fix the hardcoded path in run_app.sh
    substituteInPlace usr/lib/lise-app/run_app.sh \
      --replace "/usr/lib/lise-app" "$out/lib/lise-app"
  '';

  postFixup = ''
    for exe in Charge ETACHA4 Gemini Global KanteleHandbook LISE++ PACE4; do
      if [ -f "$out/lib/lise-app/$exe" ]; then
      wrapProgram "$out/lib/lise-app/$exe" \
      --set QT_QPA_PLATFORM xcb \
      --set QT_PLUGIN_PATH "$out/lib/lise-app/plugins" \
      --set QT_QML2_IMPORT_PATH "$out/lib/lise-app/qml" \
      --chdir "$out/lib/lise-app" 
      fi
    done

    # Wrap the shell script launcher
    wrapProgram "$out/lib/lise-app/run_app.sh" \
      --set QT_QPA_PLATFORM xcb \
      --set QT_PLUGIN_PATH "$out/lib/lise-app/plugins" \
      --set QT_QML2_IMPORT_PATH "$out/lib/lise-app/qml" \
      --chdir "$out/lib/lise-app"

    # Fix the bin symlinks to point to wrapped versions
    for bin in $out/bin/*; do
      if [ -L "$bin" ]; then
        rm "$bin"
        ln -s "$out/lib/lise-app/$(basename $(readlink usr/bin/$(basename $bin)))" "$bin"
      fi
    done


    # Update desktop file to fix
    substituteInPlace $out/share/applications/lise.desktop \
    --replace "Terminal=true" "Terminal=false"
  '';
}
