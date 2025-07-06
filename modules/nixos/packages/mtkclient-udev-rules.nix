{ pkgs, ... }:
let mtk-udev = pkgs.callPackage ../../packages/mtkclient/mtkclient-udev.nix { };
in { services.udev.packages = [ mtk-udev ]; }
