{ pkgs, ... }:
let
  boxcli = pkgs.buildNpmPackage {
    pname = "boxcli";
    version = "4.4.1";
    src = pkgs.fetchFromGitHub {
      owner = "box";
      repo = "boxcli";
      rev = "4348f0328ba379af6c270a28a8cc742a4fb07886";
      hash = "sha256-aCOXZjr5GnaSS1t0mak2S1aRFCZ6We/4lRguZHns3Ac=";
    };
    npmDepsHash = "sha256-jtmR27Dnx/nExlnmARrCxjJB764OBS54Z5lxbsKw6lA=";

    nativeBuildInputs = with pkgs; [ pkg-config python3 nodePackages.node-gyp ];

    buildInputs = with pkgs; [ libsecret ];

    dontNpmBuild = true;

    npmFlags = [ "--ignore-scripts" ];

  };
in { environment.systemPackages = [ boxcli ]; }
