{
  "e-play" = { pkgs, inputs, ... }:
    let mtkclient = pkgs.callPackage ../../packages/mtkclient/default.nix { };
    in {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/play-user.nix
        ../../modules/home-manager/waybar/waybar.nix
        ../../modules/home-manager/qutebrowser/qutebrowser.nix
        ../../modules/home-manager/windowManagers/windowManager.nix
#        ../../modules/home-manager/windowManagers/niri/settings/profile.nix
      ];
      home.packages = [ mtkclient ];
      programs.waybar.enable = true;
      programs.git = {
        enable = true;
        userName = "Ethan Todd";
        userEmail = "30243637+ewtodd@users.noreply.github.com";
        extraConfig = {
          init = { defaultBranch = "main"; };
          safe.directory = "/etc/nixos";
          core.sharedRepository = "group";
        };
      };
      xdg.desktopEntries.todoist-electron = {
        name = "Todoist";
        noDisplay = true;
      };
      FontChoice = "Ubuntu Nerd Font";
      WallpaperPath =
        "/etc/nixos/modules/home-manager/windowManagers/niri/wallpapers/eris.png";
      colorScheme = inputs.nix-colors.colorSchemes.eris;
    };
  "e-work" = { inputs, ... }: {
    home.username = "e-work";
    home.homeDirectory = "/home/e-work";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/work-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/qutebrowser/qutebrowser.nix
      ../../modules/home-manager/windowManagers/windowManager.nix
#      ../../modules/home-manager/windowManagers/niri/settings/profile.nix
    ];
    programs.bash.shellAliases = {
      phone-home = "ssh e-work@ssh.ethanwtodd.com -p 2222";
      files-home = "sftp -P 2222 e-work@ssh.ethanwtodd.com";
      vpn = ''
        sudo openconnect --protocol=anyconnect --authgroup="UMVPN-Only U-M Traffic alt" umvpn.umnet.umich.edu'';
    };
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      userName = "Ethan Todd";
      userEmail = "30243637+ewtodd@users.noreply.github.com";
      extraConfig = {
        init = { defaultBranch = "main"; };
        safe.directory = "/etc/nixos";
        core.sharedRepository = "group";
      };
    };
    WallpaperPath =
      "/etc/nixos/modules/home-manager/windowManagers/niri/wallpapers/kanagawa.png";
    FontChoice = "Ubuntu Nerd Font";
    colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
  };
  "root" = { ... }: {
    home.username = "root";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
  };
}
