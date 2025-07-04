{
  description = "Python and ROOT environment with jupyter integration.";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; # Change to your system
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          root
          liberation_ttf
          (python312.withPackages (python-pkgs:
            with python-pkgs; [
              tensorflow
              matplotlib
              numpy
              pandas
              seaborn
              scikit-learn
              mplhep
              awkward
              pynvim
              ipykernel
              cairosvg
              plotly
              kaleido
            ]))
        ];
        shellHook = ''
          mkdir -p $HOME/.local/share/jupyter/runtime
          jupyter kernelspec remove nix-python -f 2>/dev/null || true
          python -m ipykernel install --user --name nix-python --display-name "Nix Python"
        '';
      };
    };
}
