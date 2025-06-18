{ stdenv, fetchurl, dpkg, autoPatchelfHook, libgcc, libglvnd, openssl
, libgpg-error, libz, freetype, fontconfig, gmp, e2fsprogs, libdrm, mesa }:

stdenv.mkDerivation rec {
  name = "lise-app";
  version = "17.12.7";

  src = fetchurl {
    url = "https://lise.frib.msu.edu/download/Linux/lise-app_v17.12.7_all.deb";
    sha256 = "02ddizpci4lwbvj2wq65bil92nxw3kgmfwx853vn7v6ybizf5jgm";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc # Provides libstdc++.so.6
    libgcc # Provides libgcc_s.so.1
    libglvnd # Provides libGL.so.1
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

  postInstall = ''
      cat > $out/bin/.lise-setup << 'EOF'
    #!/bin/bash
    LISE_USER_DIR="$HOME/Documents/LISEcute"

    # Always remove and recreate to ensure proper symlink structure
    if [ -d "$LISE_USER_DIR" ]; then
      rm -rf "$LISE_USER_DIR"
    fi

    echo "Creating LISEcute directory with proper symlinks..."
    mkdir -p "$LISE_USER_DIR"

    # Create symlinks for all the directories LISE++ expects
    ln -sf "$1/lib/lise-app/lisecfg" "$LISE_USER_DIR/lisecfg"
    ln -sf "$1/lib/lise-app/calibrations" "$LISE_USER_DIR/calibrations"
    ln -sf "$1/lib/lise-app/config" "$LISE_USER_DIR/config"
    ln -sf "$1/lib/lise-app/data" "$LISE_USER_DIR/data"
    ln -sf "$1/lib/lise-app/degrader" "$LISE_USER_DIR/degrader"
    ln -sf "$1/lib/lise-app/files" "$LISE_USER_DIR/files"
    ln -sf "$1/lib/lise-app/options" "$LISE_USER_DIR/options"
    ln -sf "$1/lib/lise-app/CrossSections" "$LISE_USER_DIR/CrossSections"

    # Create empty directories for LISE++ to write to (results, spectra)
    mkdir -p "$LISE_USER_DIR"/{results,spectra}

    echo "LISEcute setup complete with symlinks"
    EOF
      chmod +x $out/bin/.lise-setup
      
      # Modify run_app.sh to call setup before every execution
      if [ -f $out/lib/lise-app/run_app.sh ]; then
        # Insert the setup call at the beginning of the script (after shebang)
        sed -i '2i '"$out"'/bin/.lise-setup '"$out" $out/lib/lise-app/run_app.sh
      fi
      
      # Ensure the main LISE++ executable is executable
      chmod +x $out/lib/lise-app/LISE++
  '';
}
