{
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    proton-pass
    losslesscut-bin
  ];
}
