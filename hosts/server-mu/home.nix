{
  "mu" = { pkgs, inputs, ... }: {
    home.username = "mu";
    home.homeDirectory = "/home/mu";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
    programs.git = {
      enable = true;
      userName = "Ethan Todd";
      userEmail = "30243637+ewtodd@users.noreply.github.com";
      extraConfig = {
        init = { defaultBranch = "main"; };
        safe.directory = "/etc/nixos";
      };
    };
  };

}
