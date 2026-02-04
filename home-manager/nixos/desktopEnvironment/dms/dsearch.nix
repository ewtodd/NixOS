{ pkgs, lib, ... }:
let
  isLinux = pkgs.stdenv.isLinux;
in
{
  programs.dsearch = lib.mkIf isLinux {
    enable = true;
  };
}
