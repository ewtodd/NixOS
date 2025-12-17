{
  description = "Geant4 environment with minimal ROOT and Python packages.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    utils.url = "github:ewtodd/Nuclear-Measurement-Utilities";
  };

  outputs = { self, nixpkgs, utils }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      geant4custom = pkgs.geant4.override {
        enableQt = true;
        enableOpenGLX11 = true;
        enableRaytracerX11 = true;
      };
      nm-utils = utils.packages.${system}.default;
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          root
          liberation_ttf
          geant4custom
          cmake
          xorg.libXinerama
          geant4.data.G4ABLA
          geant4.data.G4INCL
          geant4.data.G4PhotonEvaporation
          geant4.data.G4RealSurface
          geant4.data.G4EMLOW
          geant4.data.G4NDL
          geant4.data.G4PII
          geant4.data.G4SAIDDATA
          geant4.data.G4ENSDFSTATE
          geant4.data.G4PARTICLEXS
          geant4.data.G4TENDL
          geant4.data.G4RadioactiveDecay
          (python3.withPackages
            (python-pkgs: with python-pkgs; [ matplotlib numpy mplhep uproot ]))
        ];
        shellHook = ''
          # Niri-specific Wayland settings
          export QT_QPA_PLATFORM=wayland
          export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
          export G4VIS_DEFAULT_DRIVER=TSG_QT_ZB

          # AMD 7900 XTX - Force RADV (Mesa driver)
          export AMD_VULKAN_ICD=RADV
          export RADV_PERFTEST=gpl  # Enable advanced features
          export MESA_LOADER_DRIVER_OVERRIDE=radeonsi

          # Disable threaded optimization 
          export mesa_glthread=false
          export __GL_THREADED_OPTIMIZATIONS=0

          # XWayland fallback for problematic apps
          export DISPLAY=:0
          echo "ROOT version: $(root-config --version)"
          echo "Nuclear-Measurement-Utilities: ${nm-utils}"

          STDLIB_PATH="${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}"
          STDLIB_MACHINE_PATH="$STDLIB_PATH/x86_64-unknown-linux-gnu"

          ROOT_INC="$(root-config --incdir)"
          # Local first, then remote, then others
          export CPLUS_INCLUDE_PATH="$PWD/include:$STDLIB_PATH:$STDLIB_MACHINE_PATH:${nm-utils}/include:$ROOT_INC''${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"

          export PKG_CONFIG_PATH="${nm-utils}/lib/pkgconfig:$PKG_CONFIG_PATH"

          export ROOT_INCLUDE_PATH="$PWD/include:${nm-utils}/include''${ROOT_INCLUDE_PATH:+:$ROOT_INCLUDE_PATH}"
          # Local lib first means linker will use it preferentially
          export LD_LIBRARY_PATH="$PWD/lib:${nm-utils}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

        '';
      };
    };
}
