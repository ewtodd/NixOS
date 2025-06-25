{ config, lib, pkgs, ... }:
with lib;
let profile = config.Profile;
in {
  config = mkIf config.gtk.enable {
    gtk = {
      theme = if profile == "play" then {
        package = pkgs.dracula-theme;
        name = "Dracula";
      } else {
        package = pkgs.catppuccin-gtk.override {
          variant = "latte";
          accents = [ "pink" ];
        };
        name = "Catppuccin-Latte-Standard-Pink-Light";
      };

      iconTheme = if profile == "play" then {
        package = pkgs.dracula-icon-theme;
        name = "Dracula";
      } else {
        package = pkgs.catppuccin-papirus-folders.override {
          accent = "pink";
          flavor = "latte";
        };
        name = "Papirus-Light";
      };

      font = if profile == "work" then {
        name = "FiraCode";
        size = 12;
      } else {
        name = "JetBrainsMonoNF";
        size = 12;
      };
    };
    # Required for GTK4 applications
    xdg.configFile = let
      gtkTheme = config.gtk.theme;
      gtk4Dir = "${gtkTheme.package}/share/themes/${gtkTheme.name}/gtk-4.0";
    in {
      "gtk-4.0/assets".source = "${gtk4Dir}/assets";
      "gtk-4.0/gtk.css".source = "${gtk4Dir}/gtk.css";
      "gtk-4.0/gtk-dark.css".source = "${gtk4Dir}/gtk-dark.css";
    };
  };
}
