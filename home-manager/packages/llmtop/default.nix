{
  lib,
  osConfig,
  inputs,
  pkgs,
  ...
}:
let
  # Flags given by hand come after these: a second --maitred wins, more --gpu-name labels add to
  # these. makeWrapper, not makeBinaryWrapper: the binary wrapper splits --add-flags on spaces, and
  # the labels have them.
  llmtop = pkgs.symlinkJoin {
    name = "llmtop";
    paths = [ inputs.llmtop.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/llmtop --add-flags ${
        lib.escapeShellArg (
          lib.escapeShellArgs [
            "--maitred"
            "http://${osConfig.systemOptions.aiFrontAddress}:4002"
            "--gpu-name"
            "son-of-anton/0000:c7:00.0=R9700 c7"
            "--gpu-name"
            "son-of-anton/0000:cc:00.0=R9700 cc"
            "--gpu-name"
            "son-of-anton/0000:d0:00.0=8060S"
            "--gpu-name"
            "fiona/0000:03:00.0=A770M"
          ]
        )
      }
    '';
  };
in
{
  config = lib.mkIf osConfig.systemOptions.owner.e.enable {
    home.packages = [ llmtop ];
  };
}
