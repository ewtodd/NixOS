{ pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  config = lib.mkIf isLinux {
    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };
  };
}
