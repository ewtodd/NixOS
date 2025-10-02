{ pkgs, ... }:
let
  freecad-gdml-support = pkgs.freecad-wayland.overrideAttrs
    (finalAttrs: previousAttrs: {
      propagatedBuildInputs = previousAttrs.propagatedBuildInputs
        ++ [ pkgs.python3Packages.gmsh pkgs.python3Packages.lxml ];
    });
in { environment.systemPackages = [ freecad-gdml-support ]; }
