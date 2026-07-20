{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena # fleet deploy (build host)
    inputs.temple.packages.x86_64-linux.temple # temple TUI client (talks to oracle's temple-server)
  ]
  ++ (with pkgs; [
    proton-pass
    losslesscut-bin
  ]);
}
