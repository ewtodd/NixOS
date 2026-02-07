{ lib, config, ... }:
with lib;
{
  config = mkIf config.systemOptions.owner.e.enable {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
        extraFlags = [
          "--verbose"
        ];
      };
      brews = [
        "FelixKratz/formulae/borders"
        "j-x-z/tap/cocoa-way"
        "j-x-z/tap/waypipe-darwin"
      ];
      casks = [
        "karabiner-elements"
      ];
    };
  };
}
