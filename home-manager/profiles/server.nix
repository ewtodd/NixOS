{ pkgs, ... }:
{
  imports = [
    ../packages/fastfetch
    ../packages/nixvim
  ];

  scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";

  home.packages = with pkgs; [
    htop
    tmux
    ripgrep
    fd
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      fastfetch
    '';
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "TTY";
      vim_keys = true;
      proc_tree = true;
      proc_per_core = false;
      proc_mem_bytes = false;
      show_swap = false;
      io_mode = true;
      update_ms = 1000;
      base_10_sizes = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "Ethan Todd";
      user.email = "30243637+ewtodd@users.noreply.github.com";
      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };
}
