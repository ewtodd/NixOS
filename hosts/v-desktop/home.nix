{
  "v-play" = { pkgs, inputs, ... }: {
    home.username = "v-play";
    home.homeDirectory = "/home/v-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/windowManagers/windowManager.nix
    ];
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      userName = "Valarie Milton";
      userEmail = "157831739+vael3429@users.noreply.github.com";
      extraConfig = { init = { defaultBranch = "main"; }; };
    };
    WallpaperPath = "/etc/nixos/hosts/v-desktop/play.png";
    colorScheme = {
      slug = "play-dark";
      name = "Generated";
      author = "nix-colors";
      palette = {
        base00 = "1a2737";
        base01 = "434c5a";
        base02 = "6b717e";
        base03 = "9397a2";
        base04 = "bbbcc5";
        base05 = "e3e1e9";
        base06 = "e7e5ec";
        base07 = "ebeaef";
        base08 = "2880ae";
        base09 = "81757f";
        base0A = "577aab";
        base0B = "b4a3dc";
        base0C = "6a76a6";
        base0D = "d97a5e";
        base0E = "c1565e";
        base0F = "82738e";
      };
    };
  };

  "v-work" = { pkgs, inputs, ... }:
    let lisepp = pkgs.callPackage ../../packages/LISE++/default.nix { };
    in {
      home.username = "v-work";
      home.homeDirectory = "/home/v-work";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/work-user.nix
        ../../modules/home-manager/waybar/waybar.nix
        ../../modules/home-manager/windowManagers/windowManager.nix
      ];
      home.packages = [ lisepp ];
      programs.waybar.enable = true;
      programs.git = {
        enable = true;
        userName = "Valarie Milton";
        userEmail = "157831739+vael3429@users.noreply.github.com";
        extraConfig = { init = { defaultBranch = "main"; }; };
      };
      WallpaperPath = "/etc/nixos/hosts/v-desktop/work.png";
      colorScheme = {
        slug = "work";
        name = "Work";
        palette = {
          base00 = "#271C3A";
          base01 = "#100323";
          base02 = "#3E2D5C";
          base03 = "#5D5766";
          base04 = "#BEBCBF";
          base05 = "#DEDCDF";
          base06 = "#EDEAEF";
          base07 = "#BBAADD";
          base08 = "#A92258";
          base09 = "#918889";
          base0A = "#804ead";
          base0B = "#C6914B";
          base0C = "#7263AA";
          base0D = "#8E7DC6";
          base0E = "#953B9D";
          base0F = "#59325C";
        };
      };
    };

  "root" = { ... }: {
    home.username = "root";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
  };

}
