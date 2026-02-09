{ pkgs, ... }:
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
  };
}
