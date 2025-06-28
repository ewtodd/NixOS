{ config, pkgs, ... }: {
  wayland.windowManager.sway = {
    config = { startup = [{ command = "blueman-applet"; }]; };
  };
}
