{ osConfig, lib, ... }:

let
  windowManager = osConfig.WindowManager;

  _ = if windowManager == "gnome" then
    throw
    "Unsupported window manager: ${windowManager}. You don't need any of these things."
  else
    null;
in {
  imports = [ ] ++ lib.optionals (windowManager == "sway") [ ./sway/sway.nix ] ++ lib.optionals (windowManager == "niri") [ ./niri/niri.nix ];
}
