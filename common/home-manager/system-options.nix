{ lib, ... }:

with lib;

{
  options = {
    Profile = mkOption {
      type = types.enum [ "work" "play" ];
      default = "play";
      description = "Profile for user (work/play)";
    };
  };
}
