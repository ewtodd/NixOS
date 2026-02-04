{ lib, pkgs, ... }:
{
  imports = lib.optionals pkgs.stdenv.isLinux [
    ./desktopEnvironment
    ./theming
    ./xdg
  ];
}
