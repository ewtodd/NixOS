{
  unstable,
  ...
}:
{
  environment.systemPackages = with unstable; [
    claude-code
    proton-pass
    protonvpn-gui
  ];
}
