{
  "e-play" = { ... }: {
    home.username = "e-play";
    home.homeDirectory = "/home/e-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/zettelkasten/zk.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/windowManagers/windowManager.nix
    ];
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      userName = "Ethan Todd";
      userEmail = "30243637+ewtodd@users.noreply.github.com";
      extraConfig = { init = { defaultBranch = "main"; }; };
    };
  };

  "e-work" = { ... }: {
    home.username = "e-work";
    home.homeDirectory = "/home/e-work";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/work-user.nix
      ../../modules/home-manager/zettelkasten/zk.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/windowManagers/windowManager.nix
    ];
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      userName = "Ethan Todd";
      userEmail = "30243637+ewtodd@users.noreply.github.com";
      extraConfig = { init = { defaultBranch = "main"; }; };
    };
  };

  "root" = { ... }: {
    home.username = "root";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
  };
}
