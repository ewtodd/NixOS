{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    openconnect
    protonmail-desktop
    proton-pass
    protonvpn-gui
  ];
}
