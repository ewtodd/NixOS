{ ... }: {
  wayland.windowManager.hyprland = {
    settings = {
      monitor =
        [ "eDP-1,2256x1504@59.999,0x0,1.333333" "DP-3,1920x1080,-1920x0,1" ];
    };
  };
  home.pointerCursor = { size = 48; };
}
