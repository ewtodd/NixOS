{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    claude-code
    proton-pass
  ];
}
