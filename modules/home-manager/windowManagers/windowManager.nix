{ osConfig, lib, ... }:

let windowManager = osConfig.WindowManager;
in {
  imports = [ ] ++ lib.optionals (windowManager == "sway") [ ./sway/sway.nix ];
}
