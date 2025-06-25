{ config, lib, pkgs, ... }:

with lib;

let
  profile = config.Profile;

  # Create kanagawa icon theme with inheritance
  kanagawa-with-inheritance = pkgs.kanagawa-icon-theme.overrideAttrs
    (oldAttrs: {
      postInstall = (oldAttrs.postInstall or "") + ''
        # Add inheritance to closest matching themes
        for theme_dir in $out/share/icons/*/; do
          if [ -f "$theme_dir/index.theme" ]; then
            # Remove any existing Inherits line
            sed -i '/^Inherits=/d' "$theme_dir/index.theme"
            
            # Add inheritance ordered by visual similarity to Kanagawa
            echo "Inherits=Papirus-Dark,breeze-dark,Adwaita,breeze,hicolor" >> "$theme_dir/index.theme"
          fi
        done
      '';
    });

in {
  config = mkIf config.gtk.enable {
    # Ensure fallback icon packages are available
    home.packages = with pkgs; [
      papirus-icon-theme
      libsForQt5.breeze-icons
      adwaita-icon-theme
      hicolor-icon-theme
    ];

    gtk = {
      theme = if profile == "play" then {
        package = pkgs.dracula-theme;
        name = "Dracula";
      } else {
        package = pkgs.kanagawa-gtk-theme;
        name = "Kanagawa";
      };

      iconTheme = if profile == "play" then {
        package = pkgs.dracula-icon-theme;
        name = "Dracula";
      } else {
        package = kanagawa-with-inheritance; # Use the modified version
        name = "Kanagawa";
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
