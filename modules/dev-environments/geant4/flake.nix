{
  description = "Geant4 environment with minimal ROOT and Python packages.";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Change to your system
      pkgs = nixpkgs.legacyPackages.${system};
      geant4custom = pkgs.geant4.override {
        enableQt = true;
        enableOpenGLX11 = true;
        enableRaytracerX11 = true;
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          root
          liberation_ttf
          geant4custom
          cmake
          libsForQt5.full
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
            (python-pkgs: with python-pkgs; [ matplotlib numpy mplhep uproot]))
        ];
        shellHook = ''
          export QT_QPA_PLATFORM="xcb";
          export LIBGL_ALWAYS_SOFTWARE=1
        '';
      };
    };
}
