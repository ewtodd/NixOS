{ osConfig, lib, ... }:

let
  windowManager = osConfig.WindowManager;

  # Standalone validation
  _ = if windowManager == "cosmic" || windowManager == "hyprland" then
    throw "Unsupported window manager: ${windowManager}"
  else
    null;
in {
  imports = [ ] ++ lib.optionals (windowManager == "sway") [ ./sway/sway.nix ]
    ++ lib.optionals (windowManager == "papersway")
    [ ./papersway/papersway.nix ]
    ++ lib.optionals (windowManager == "niri") [ ./niri/niri.nix ];

}
