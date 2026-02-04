{
  "e-host" =
    { inputs, ... }:
    {
      home.username = "e-host";
      home.stateVersion = "25.11";
      imports = [
        ./amethyst.nix
        ./keyboard.nix
        ../../home-manager/packages/nixvim
        ../../home-manager/packages/kitty
        ../../home-manager/packages/git
        ../../home-manager/packages/fastfetch
        ../../home-manager/system-options
      ];
      colorScheme = inputs.nix-colors.colorSchemes.harmonic16-dark;

      programs.zsh = {
        enable = true;
        shellAliases = {
          vim = "nvim";
          nrs = "nh darwin switch /etc/nixos";
          ":q" = "exit";
        };
      };

      programs.starship = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
