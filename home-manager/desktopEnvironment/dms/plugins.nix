{
  ...
}:
{
  config = {
    programs.dank-material-shell = {
      managePluginSettings = true;
      plugins = {
        dankPomodoroTimer = {
          enable = true;
        };
        calculator = {
          enable = true;
        };
        dankLauncherKeys = {
          enable = true;
        };
      };
    };
  };

}
