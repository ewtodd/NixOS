{ pkgs, inputs, lib, ... }:
let
  obs-studio =
    (pkgs.obs-studio.override { browserSupport = false; }).overrideAttrs
    (oldAttrs: {
      version = "31.1.0-beta2";
      src = pkgs.fetchFromGitHub {
        owner = "obsproject";
        repo = "obs-studio";
        rev = "31.1.0-beta2";
        hash = "sha256-Ck2Sw51aNzetFhmLvC600fAdN5BJ9CeCwzhcXxAqsR4=";
      };
      nativeBuildInputs = oldAttrs.nativeBuildInputs
        ++ [ pkgs.extra-cmake-modules ];
      patches = [
        (pkgs.fetchurl {
          url =
            "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-25.05/pkgs/applications/video/obs-studio/fix-nix-plugin-path.patch";
          hash = "sha256-RRbawNqIaR3UFvO3hUjMtT8je6QBbgdnk6wOfR3PHNo=";
        })
      ];
      postUnpack = ''
        mkdir -p $sourceRoot/plugins/obs-browser
        touch $sourceRoot/plugins/obs-browser/CMakeLists.txt
        mkdir -p $sourceRoot/plugins/obs-websocket
        touch $sourceRoot/plugins/obs-websocket/CMakeLists.txt
      '';
    });
in {
  programs.obs-studio = {
    enable = true;
    package = obs-studio;
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };

}
