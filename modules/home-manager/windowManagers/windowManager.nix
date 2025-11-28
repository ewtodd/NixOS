{ osConfig, lib, ... }:

let windowManager = osConfig.WindowManager;
in {
  imports = [ ] ++ lib.optionals (windowManager == "niri") [ ./niri/niri.nix ];
}
