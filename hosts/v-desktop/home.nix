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
      programs.git = {
        enable = true;
        userName = "Valarie Milton";
        userEmail = "157831739+vael3429@users.noreply.github.com";
        extraConfig = { init = { defaultBranch = "main"; }; };
      };
      WallpaperPath = "/etc/nixos/hosts/v-desktop/play.jpg";
      colorScheme = nix-colors-lib.colorSchemeFromPicture {
        path = "./play.jpg";
        variant = "dark";
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
      programs.git = {
        enable = true;
        userName = "Valarie Milton";
        userEmail = "157831739+vael3429@users.noreply.github.com";
        extraConfig = { init = { defaultBranch = "main"; }; };
      };
      WallpaperPath = "/etc/nixos/hosts/v-desktop/work.jpg";
      colorScheme = nix-colors-lib.colorSchemeFromPicture {
        path = "./work.jpg";
        variant = "dark";
      };
    };

  "root" = { ... }: {
    home.username = "root";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
  };

}
