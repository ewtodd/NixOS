{
  "e-play" =
    { pkgs, inputs, ... }:
    let
      mtkclient = pkgs.callPackage ../../packages/mtkclient/default.nix { };
    in
    {
      home.username = "e-play";
      home.homeDirectory = "/home/e-play";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/play-user.nix
        ../../modules/home-manager/dms/dms.nix
        ../../modules/home-manager/qutebrowser/qutebrowser.nix
        ../../modules/home-manager/niri/niri.nix
      ];
      home.packages = [ mtkclient ];
      programs.git = {
        enable = true;
        settings = {
          user.name = "Ethan Todd";
          user.email = "30243637+ewtodd@users.noreply.github.com";
          init = {
            defaultBranch = "main";
          };
          safe.directory = "/etc/nixos";
          core.sharedRepository = "group";
        };
      };
      programs.bash.shellAliases = {
        phone-home = "ssh e-play@ssh.ethanwtodd.com -p 2222";
        files-home = "sftp -P 2222 e-play@ssh.ethanwtodd.com";
      };

      FontChoice = "Ubuntu Nerd Font";
      WallpaperPath = "/etc/nixos/modules/home-manager/niri/wallpapers/eris.png";
      colorScheme = inputs.nix-colors.colorSchemes.eris;
    };
  "e-work" =
    { inputs, ... }:
    {
      home.username = "e-work";
      home.homeDirectory = "/home/e-work";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/work-user.nix
        ../../modules/home-manager/dms/dms.nix
        ../../modules/home-manager/qutebrowser/qutebrowser.nix
        ../../modules/home-manager/niri/niri.nix
      ];
      programs.bash.shellAliases = {
        phone-home = "ssh e-work@ssh.ethanwtodd.com -p 2222";
        files-home = "sftp -P 2222 e-work@ssh.ethanwtodd.com";
        vpn = ''sudo openconnect --protocol=anyconnect --authgroup="UMVPN-Only U-M Traffic alt" umvpn.umnet.umich.edu'';
      };
      programs.git = {
        enable = true;
        settings = {
          user.name = "Ethan Todd";
          user.email = "30243637+ewtodd@users.noreply.github.com";
          init = {
            defaultBranch = "main";
          };
          safe.directory = "/etc/nixos";
          core.sharedRepository = "group";
        };
      };

      WallpaperPath = "/etc/nixos/modules/home-manager/niri/wallpapers/kanagawa.png";
      FontChoice = "Ubuntu Nerd Font";
      colorScheme = inputs.nix-colors.colorSchemes.kanagawa;
    };
  "root" =
    { ... }:
    {
      home.username = "root";
      home.stateVersion = "25.05";
      imports = [ ../../common/home-manager/root-user.nix ];
    };
}
