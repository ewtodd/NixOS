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
        shellHook = "";
      };
    };
}
