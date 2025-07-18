{
  "e-play" = { pkgs, ... }:
    let mtkclient = pkgs.callPackage ../../packages/mtkclient/default.nix { };
    in {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/play-user.nix
        ../../modules/home-manager/zettelkasten/zk.nix
        ../../modules/home-manager/waybar/waybar.nix
        ../../modules/home-manager/windowManagers/windowManager.nix
      ];
      home.packages = [ mtkclient ];
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
    programs.bash.shellAliases = {
      phone-home = "ssh e-work@ssh.ethanwtodd.com -p 2222";
      files-home = "sftp e-work@ssh.ethanwtodd.com -p 2222";
    };
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
