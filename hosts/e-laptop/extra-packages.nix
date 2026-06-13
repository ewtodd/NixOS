{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena # fleet deploy (apply-local)
  ]
  ++ (with pkgs; [
    proton-pass
  ]);
}
