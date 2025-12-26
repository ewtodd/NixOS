{ pkgs, ... }:
let
  dmsPlugins = pkgs.fetchFromGitHub {
    owner = "AvengeMedia";
    repo = "dms-plugins";
    rev = "8715ca35b61d7c6275a300fa4992e2b0490f70f7";
    hash = "sha256-6ScuVcvSaXc35Sf1iwtCy8aM/pFID3+0G4NRMw8aBcM=";
  };
  jsonFormat = pkgs.formats.json { };
in
{

  xdg.configFile."DankMaterialShell/plugin_settings.json" = {
    source = jsonFormat.generate "plugin_settings.json" {
      dankPomodoroTimer.enabled = true;
    };
  };

  xdg.configFile."DankMaterialShell/plugins/" = {
    source = dmsPlugins;
    recursive = true;
  };

}
