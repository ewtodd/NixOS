{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    proton-pass
    protonvpn-gui
    claude-code
  ];
}
