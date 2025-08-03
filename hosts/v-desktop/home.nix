{
  "v-play" = { pkgs, inputs, ... }:
    let nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
    in {
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
        slug = "play";
        name = "Play";
        palette = {
          base00 = "#604860";
          base01 = "#003030";
          base02 = "#486090";
          base03 = "#786060";
          base04 = "#C0A8D8";
          base05 = "#FFC0C0";
          base06 = "#FFD8D8";
          base07 = "#F0A890";
          base08 = "#486090";
          base09 = "#7878A8";
          base0A = "#C07878";
          base0B = "#F09078";
          base0C = "#FFA8A8 ";
          base0D = "#F0C0C0";
          base0E = "#A890C0";
          base0F = "#FFC0C0";
        };
      };
    };

  "v-work" = { pkgs, inputs, ... }:
    let
      nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
      lisepp = pkgs.callPackage ../../packages/LISE++/default.nix { };
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
