{ pkgs, inputs, ... }:
let
  colorScheme = inputs.nix-colors.colorSchemes.grayscale-dark;
  schemeName = colorScheme.slug;
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
in {
  imports = [ ./sway/sway-de.nix ];
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    excludePackages = with pkgs; [ xterm ];
    displayManager.gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false;
    };
  };

  #  programs.regreet = {
  #    enable = true;
  #    settings = {
  #      background = {
  #        path = ./grayscale-dark.png;
  #        fit = "Cover";
  #      };
  #      widget.clock = { format = "%I:%M, %d %b %Y"; };
  #      appearance = { greeting_msg = "NO DOGS!"; };
  #    };
  #    theme = {
  #      package = nix-colors-lib.gtkThemeFromScheme { scheme = colorScheme; };
  #      name = schemeName;
  #    };
  #    cursorTheme = {
  #      package = pkgs.dracula-theme;
  #      name = "Dracula-cursors";
  #    };
  #    font = {
  #      package = pkgs.nerd-fonts.fira-code;
  #      name = "Fira Code";
  #    };
  #    cageArgs = [ "-s" "-m" "last" ];
  #  };
  #
  #  # Custom CSS styling that creates the beautiful look from your image
  #  environment.etc."greetd/regreet.css" = {
  #    text = ''
  #      /* Define color variables using your nix-colors palette */
  #      @define-color surface #${colorScheme.palette.base01};
  #      @define-color on_surface #${colorScheme.palette.base05};
  #      @define-color shadow #${colorScheme.palette.base00};
  #      @define-color primary_container #${colorScheme.palette.base0D};
  #      @define-color on_primary_container #${colorScheme.palette.base00};
  #      @define-color primary #${colorScheme.palette.base0C};
  #      @define-color on_primary #${colorScheme.palette.base07};
  #      @define-color error #${colorScheme.palette.base08};
  #      @define-color on_error_container #${colorScheme.palette.base08};
  #      @define-color on_error #${colorScheme.palette.base07};
  #      @define-color surface_variant #${colorScheme.palette.base02};
  #      @define-color surface_dim #${colorScheme.palette.base01};
  #      @define-color on_surface_variant #${colorScheme.palette.base0E};
  #      @define-color tertiary #${colorScheme.palette.base0E};
  #
  #      * {
  #        all: unset;
  #      }
  #      picture {
  #        filter: blur(0.1rem);
  #      }
  #      box.horizontal>button.default.suggested-action.text-button {
  #        background: @primary_container;
  #        color: @on_primary_container;
  #        padding: 12px;
  #        margin: 0 8px;
  #        border-radius: 12px;
  #        box-shadow: 0 0 2px 1px alpha(@shadow, .6);
  #        transition: background .3s ease-in-out;
  #      }
  #      box.horizontal>button.default.suggested-action.text-button:hover {
  #        background: @primary;
  #        color: @on_primary;
  #      }
  #      box.horizontal>button.text-button {
  #        background: alpha(@error, .1);
  #        color: @on_error_container;
  #        padding: 12px;
  #        border-radius: 12px;
  #        transition: background .3s ease-in-out;
  #      }
  #      box.horizontal>button.text-button:hover {
  #        background: alpha(@error, .3);
  #      }
  #      box.bottom.vertical>box.horizontal>button.destructive-action.text-button {
  #        background: @surface_variant;
  #        color: @on_error_container;
  #        padding: 12px;
  #        border-radius: 12px;
  #        transition: background .3s ease-in-out;
  #      }
  #      box.bottom.vertical>box.horizontal>button.destructive-action.text-button:hover {
  #        background: @error;
  #        color: @on_error;
  #      }
  #      combobox {
  #        background: @surface_variant;
  #        color: @on_surface;
  #        border-radius: 12px;
  #        padding: 12px;
  #        box-shadow: 0 0 0 1px alpha(@shadow, .6);
  #      }
  #      combobox:disabled {
  #        background: @surface_dim;
  #        color: alpha(@on_surface_variant, .6);
  #        border-radius: 12px;
  #        padding: 12px;
  #        box-shadow: none;
  #      }
  #      modelbutton.flat {
  #        background: @surface_variant;
  #        padding: 6px;
  #        margin: 2px;
  #        border-radius: 8px;
  #        border-spacing: 6px;
  #      }
  #      modelbutton.flat:hover {
  #        background: alpha(@tertiary, .2);
  #      }
  #      button.image-button.toggle {
  #        margin-right: 36px;
  #        padding: 12px;
  #        border-radius: 12px;
  #      }
  #      button.image-button.toggle:hover {
  #        background: @surface;
  #      }
  #      button.image-button.toggle:disabled {
  #        background: @surface_dim;
  #        color: alpha(@on_surface_variant, .6);
  #        margin-right: 36px;
  #        padding: 12px;
  #        border-radius: 12px;
  #      }
  #      combobox>popover {
  #        background: @surface_variant;
  #        color: @on_surface_variant;
  #        border-radius: 12px;
  #        border: 1px solid @tertiary;
  #        padding: 2px 12px;
  #      }
  #      combobox>popover>contents {
  #        padding: 2px;
  #      }
  #      combobox:hover {
  #        background: alpha(@tertiary, .2);
  #      }
  #      entry.password {
  #        border: 2px solid @primary;
  #        border-radius: 12px;
  #        padding: 12px;
  #      }
  #      entry.password:hover {
  #        border: 2px solid @primary;
  #      }
  #      tooltip {
  #        background: @surface;
  #        color: @on_surface;
  #        padding: 12px;
  #        border-radius: 12px;
  #      }
  #      frame.background.top {
  #        font-size: 1.2rem;
  #        padding: 8px;
  #        background: @surface;
  #        margin-top: 15px; 
  #        border--radius: 12px;
  #      }
  #
  #    '';
  #    mode = "0644";
  #  };
}
