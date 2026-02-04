{ lib, pkgs, ... }:
{
  programs.zathura = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
    };
  };
}
