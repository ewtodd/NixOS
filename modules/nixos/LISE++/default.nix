{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
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
  mesa,
}:

stdenv.mkDerivation rec {
  name = "lise-app";
  version = "17.12.7";

  src = fetchurl {
    url = "https://lise.frib.msu.edu/download/Linux/previous_versions/lise-app_v17.12.7_all.deb";
    sha256 = "02ddizpci4lwbvj2wq65bil92nxw3kgmfwx853vn7v6ybizf5jgm";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
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
    mesa
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    mkdir -p $out
    cp -r usr/* $out/
  '';

  postPatch = ''
    # Fix hardcoded paths in run_app.sh before Nix processes it
    substituteInPlace usr/lib/lise-app/run_app.sh \
      --replace "/usr/lib/lise-app" "$out/lib/lise-app"

    # Fix any other scripts that might have hardcoded paths
    find usr/bin -type f -executable | while read script; do
      if grep -q "/usr/lib/lise-app" "$script" 2>/dev/null; then
        substituteInPlace "$script" \
          --replace "/usr/lib/lise-app" "$out/lib/lise-app"
      fi
    done
  '';

}
