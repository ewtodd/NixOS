{ pkgs, osConfig, ... }:
let
  e = osConfig.systemOptions.owner.e.enable;
  isLaptop = osConfig.systemOptions.deviceType.laptop.enable;
  margins = 10;
  gap = 10;
  nWindows = 3;
  height =
    if isLaptop then
      builtins.floor ((1504 - 2 * margins - nWindows * gap) / (nWindows * 1.35))
    else
      (
        if e then
          builtins.floor ((1440 - 2 * margins - nWindows * gap) / nWindows)
        else
          builtins.floor ((1080 - 2 * margins - nWindows * gap) / nWindows)
      );
in
{
  config = {
    services.udiskie = {
      enable = true;
      settings = {
        program_options = {
          tray = "auto";
          file_manager = "${pkgs.nautilus}/bin/nautilus";
        };
      };
    };
    services.gnome-keyring.enable = true;
    programs.niri-sidebar = {
      enable = true;
      settings = {
        geometry = {
          width = 500;
          height = height;
          gap = gap;
        };
        margins = {
          top = margins;
          right = margins;
          left = margins;
          bottom = margins;
        };
        interaction = {
          position = if e then "left" else "right";
          peek = 15;
          sticky = true;
          auto_focus_layer = true;
        };
      };
      systemd.enable = true;
    };
  };
}
