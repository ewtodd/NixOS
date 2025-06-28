{ config, pkgs, ... }: {

  programs.niri.settings = {
    spawn-at-startup = [{ command = [ "blueman-applet" ]; }];
  };
}
