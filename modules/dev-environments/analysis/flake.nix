{
  description = "Python and ROOT environment with jupyter integration.";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Change to your system
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          root
          liberation_ttf
          docker
          (python3.withPackages (python-pkgs:
            with python-pkgs; [
              matplotlib
              numpy
              pandas
              tables
              seaborn
              scikit-learn
              mplhep
              awkward
              pynvim
              ipykernel
              cairosvg
              plotly
              kaleido
              pyarrow
              uproot
              h5py
            ]))
        ];
        shellHook = ''
          STDLIB_PATH="${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}"
          STDLIB_MACHINE_PATH="$STDLIB_PATH/x86_64-unknown-linux-gnu"
          export CPLUS_INCLUDE_PATH="$STDLIB_PATH:$STDLIB_MACHINE_PATH:$PWD/include:$(root-config --incdir):$CPLUS_INCLUDE_PATH"
          export ROOT_INCLUDE_PATH="$PWD/include:$(root-config --incdir)"
          export LD_LIBRARY_PATH="$PWD/lib:$LD_LIBRARY_PATH"

          echo "C++ stdlib: $STDLIB_PATH"
        '';
      };
    };
}
