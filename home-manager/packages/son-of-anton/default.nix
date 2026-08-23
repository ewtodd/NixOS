{
  pkgs,
  inputs,
  ...
}:
let
  sonOfAntonPkg = inputs.son-of-anton.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = {
    home.packages = [ sonOfAntonPkg ];
  };
}
