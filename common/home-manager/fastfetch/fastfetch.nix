{ config, pkgs, ... }: {
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
          keyColor = "red";
          format = "{2}";
        }
        {
          type = "bios";
          key = "├  ";
          keyColor = "red";
          format = "{vendor}-{version}";
        }
        {
          type = "kernel";
          key = "├  ";
          keyColor = "red";
        }
        {
          type = "packages";
          key = "├ 󰏖 ";
          keyColor = "red";
        }
        {
          type = "shell";
          key = "└  ";
          keyColor = "red";
        }
        "break"
        {
          type = "wm";
          key = "  DE/WM";
          format = "{process-name} ({version} ({protocol-name})";
          keyColor = "blue";
        }
        {
          type = "lm";
          key = "├ 󰧨 ";
          keyColor = "blue";
        }
        {
          type = "wmtheme";
          key = "├  ";
          keyColor = "blue";
        }
        {
          type = "theme";
          key = "├  ";
          keyColor = "blue";
        }
        {
          type = "icons";
          key = "├ 󰀻 ";
          keyColor = "blue";
        }
        {
          type = "terminal";
          key = "└  ";
          keyColor = "blue";
        }
        "break"
        {
          type = "host";
          key = "󰌢  PC";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "├ 󰻠 ";
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "├ 󰍛 ";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "├  ";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "├ 󰑭 ";
          keyColor = "green";
        }
        {
          type = "swap";
          key = "└ 󰓡 ";
          keyColor = "green";
        }
        "break"
        "colors"
      ];
    };
  };
}
