{ osConfig, ... }:
let
  format = if osConfig.WindowManager == "sway" then
    "{process-name} ({version} ({protocol-name})"
  else
    "{process-name} {version} ({protocol-name})";
in {
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = { padding = { top = 2; }; };
      display = { separator = " -> "; };
      modules = [
        "title"
        "separator"
        {
          type = "os";
          key = " OS";
          keyColor = "31";
          format = "{2}";
        }
        {
          type = "bios";
          key = "├  ";
          keyColor = "31";
          format = "{vendor}-{version}";
        }
        {
          type = "kernel";
          key = "├  ";
          keyColor = "31";
        }
        {
          type = "packages";
          key = "├ 󰏖 ";
          keyColor = "31";
        }
        {
          type = "shell";
          key = "└  ";
          keyColor = "31";
        }
        "break"
        {
          type = "wm";
          key = "  DE/WM";
          format = "${format}";
          keyColor = "35";
        }
        {
          type = "lm";
          key = "├ 󰧨 ";
          keyColor = "35";
        }
        {
          type = "wmtheme";
          key = "├  ";
          keyColor = "35";
        }
        {
          type = "theme";
          key = "├  ";
          keyColor = "35";
        }
        {
          type = "icons";
          key = "├ 󰀻 ";
          keyColor = "35";
        }
        {
          type = "terminal";
          key = "└  ";
          keyColor = "35";
        }
        "break"
        {
          type = "host";
          key = "󰌢  PC";
          keyColor = "32";
        }
        {
          type = "cpu";
          key = "├ 󰻠 ";
          keyColor = "32";
        }
        {
          type = "gpu";
          key = "├ 󰍛 ";
          keyColor = "32";
        }
        {
          type = "disk";
          key = "├  ";
          keyColor = "32";
        }
        {
          type = "memory";
          key = "├ 󰑭 ";
          keyColor = "32";
        }
        {
          type = "swap";
          key = "└ 󰓡 ";
          keyColor = "32";
        }
        "break"
        "colors"
      ];
    };
  };
}
