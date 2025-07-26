{ osConfig, lib, ... }:

let
  windowManager = osConfig.WindowManager;

  # Standalone validation
  _ = if windowManager == "gnome" then
    throw
    "Unsupported window manager: ${windowManager}. You don't need any of these things."
  else
    null;
in {
  imports = [ ] ++ lib.optionals (windowManager == "sway") [ ./sway/sway.nix ];

}
