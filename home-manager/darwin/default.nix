{ lib, pkgs, config, osConfig ? null, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable or false else false;
in
{
  imports = lib.optionals (isDarwin && isEOwner) [
    ./amethyst.nix
    ./keyboard.nix
  ];

  # Additional Darwin-specific configurations can go here
}
