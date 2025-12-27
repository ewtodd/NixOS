{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openconnect
    proton-pass
    protonvpn-gui
  ];
}
