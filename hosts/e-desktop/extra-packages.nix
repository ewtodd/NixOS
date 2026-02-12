{
  unstable,
  ...
}:
{
  environment.systemPackages = with unstable; [
    proton-pass
    protonvpn-gui
    claude-code
  ];
}
