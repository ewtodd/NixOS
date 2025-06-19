{
  "v-play" = { config, pkgs, ... }: {
    home.username = "v-play";
    home.homeDirectory = "/home/v-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/kitty/kitty.nix
    ];
  };

  "v-work" = { config, pkgs, ... }:
    let lisepp = pkgs.callPackage ../../packages/LISE++/default.nix { };
    in {
      home.username = "v-work";
      home.homeDirectory = "/home/v-work";
      home.stateVersion = "25.05";
      imports = [
        ../../common/home-manager/work-user.nix
        ../../modules/home-manager/kitty/kitty.nix
      ];
      home.packages = [ lisepp ];
    };
}
