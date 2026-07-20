{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena # fleet deploy (build host)
  ]
  ++ (with pkgs; [
    proton-pass
    losslesscut-bin
  ]);
}
