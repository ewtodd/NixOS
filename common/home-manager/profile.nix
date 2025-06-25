{ config, lib, ... }:

with lib; {
  options.profile = mkOption {
    type = types.enum [ "work" "play" ];
    default = "play";
    description = "User profile (work or play)";
  };
}
