{ pkgs, inputs, ... }:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena # fleet deploy (colmena apply --on <hosts>)
  ]
  ++ (with pkgs; [
    proton-pass
  ]);
}
