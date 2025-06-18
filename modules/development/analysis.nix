let pkgs = import <nixpkgs> { };
in pkgs.mkShell {
  packages = [
    pkgs.root
    pkgs.liberation_ttf
    (pkgs.python3.withPackages (python-pkgs:
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
        jupyter-client
        cairosvg
        plotly
        kaleido
      ]))
  ];
}
