{ config, lib, pkgs, inputs, ... }:

with lib;

let
  schemeName = config.colorScheme.slug;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in {
  config = mkIf config.gtk.enable {

    gtk = {
      theme = {
        package =
          nix-colors-lib.gtkThemeFromScheme { scheme = config.colorScheme; };
        name = schemeName;
      };

      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };

      font = {
        name = "JetBrainsMonoNF";
        size = 13;
      };
      gtk3.extraCss = ''
        .nautilus-window placessidebar.sidebar,
        .nautilus-window.maximized placessidebar.sidebar {
          background-color: @theme_bg_color;
        }

        .nautilus-window placessidebar.sidebar row.sidebar-row {
          background-color: transparent;
        }

        .nautilus-window placessidebar.sidebar row.sidebar-row:selected {
          background-color: @theme_selected_bg_color;
        }
      '';

      gtk4.extraCss = ''
        .nautilus-window placessidebar.sidebar,
        .nautilus-window.maximized placessidebar.sidebar {
          background-color: @theme_bg_color;
        }

        .nautilus-window placessidebar.sidebar row.sidebar-row {
          background-color: transparent;
        }

        .nautilus-window placessidebar.sidebar row.sidebar-row:selected {
          background-color: @theme_selected_bg_color;
        }
      '';
    };

    home.sessionVariables = {
      XDG_DATA_DIRS =
        "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
    };

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
