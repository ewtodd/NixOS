{
  "v-play" = { config, pkgs, ... }: {
    home.username = "v-play";
    home.homeDirectory = "/home/v-play";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/play-user.nix ];

  };

  "v-work" = { config, pkgs, lib, ... }:
    let lisepp = pkgs.callPackage ../../packages/LISE++/default.nix { };
    in {
      home.username = "v-work";
      home.homeDirectory = "/home/v-work";
      home.stateVersion = "25.05";
      imports = [ ../../common/home-manager/work-user.nix ];
      home.packages = [ lisepp ];
      Profile = lib.mkForce "play";
    };
}
