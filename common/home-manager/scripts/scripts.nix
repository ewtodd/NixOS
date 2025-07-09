{ lib, ... }:
with lib; {
  imports = mkIf (profile == "work") [ ./work-scripts.nix ];
}
