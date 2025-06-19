let pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  packages = with pkgs; [
    root
    liberation_ttf
    (python3.withPackages (python-pkgs:
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
    python -m ipykernel install --user --name nix-python --display-name "Nix Python"
  '';
}
