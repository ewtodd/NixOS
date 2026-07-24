{
  pkgs,
  inputs,
  ...
}:
let
  templePkg = inputs.temple.packages.${pkgs.stdenv.hostPlatform.system}.temple;

  templeWrapped = pkgs.writeShellScriptBin "temple" ''
    exec ${templePkg}/bin/temple \
      --server https://temple.ethanwtodd.com \
      "$@"
  '';
in
{
  config = {
    home.packages = [ templeWrapped ];
  };
}
