{ inputs, config, ... }:
let
  colors = config.colorScheme.palette;
  unstable = import inputs.unstable { system = "x86_64-linux"; };
in {
  wayland.windowManager.hyprland = {
    plugins = with unstable.hyprlandPlugins; [ hyprexpo ];
    settings = {
      plugin = {
        hyprexpo = {
          columns = 3;
          gap_size = 5;
          workspace_method = "first 1";
          gesture_distance = 0;
        };
      };
      bind = [ "SUPER, TAB,hyprexpo:expo, toggle" ];
    };
  };
}
