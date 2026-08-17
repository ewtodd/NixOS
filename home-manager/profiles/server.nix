{ pkgs, ... }:
{
  imports = [
    ../packages/btop
    ../packages/fastfetch
    ../packages/nixvim
  ];

  scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";

  home.packages = with pkgs; [
    ripgrep
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
