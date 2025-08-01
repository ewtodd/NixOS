{ pkgs, ... }:
let
  swayosdStyle = pkgs.writeText "swayosd-style.css" ''
    window#osd {
      border-radius: 10px;
      border: none;
      background: #{"alpha(@theme_bg_color, 0.8)"};

      #container {
        margin: 16px;
      }

      image,
      label {
        color: #{"@theme_fg_color"};
      }

      progressbar:disabled,
      image:disabled {
        opacity: 0.5;
      }

      progressbar {
        min-height: 6px;
        border-radius: 10px;
        background: transparent;
        border: none;
      }
      trough {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #{"alpha(@theme_fg_color, 0.5)"};
      }
      progress {
        min-height: inherit;
        border-radius: inherit;
        border: none;
        background: #{"@theme_fg_color"};
      }
    }
  '';
in {
  services.swayosd = {
    enable = true;
    stylePath = swayosdStyle;
    topMargin = 0.85;
  };
}
