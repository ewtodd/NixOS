{ pkgs, ... }:
let
  dmsPlugins = pkgs.fetchFromGitHub {
    owner = "AvengeMedia";
    repo = "dms-plugins";
    rev = "8715ca35b61d7c6275a300fa4992e2b0490f70f7";
    hash = "sha256-6ScuVcvSaXc35Sf1iwtCy8aM/pFID3+0G4NRMw8aBcM=";
  };
in
{
  programs.dank-material-shell = {
    managePluginSettings = true;
    plugins = {
      dankPomodoroTimer = {
        enable = true;
        src = "${dmsPlugins}/DankPomodoroTimer";
      };
    };
  };

}
