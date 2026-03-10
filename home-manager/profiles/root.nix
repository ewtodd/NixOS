{ pkgs, ... }:
{
  imports = [
    ../default.nix
  ];

  Profile = "root";
  scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
}
