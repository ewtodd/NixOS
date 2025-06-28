{
  "v-play" = { config, pkgs, ... }: {
    home.username = "v-play";
    home.homeDirectory = "/home/v-play";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/play-user.nix ];
    programs.git = {
      enable = true;
      userName = "Valarie Milton";
      userEmail = "157831739+vael3429@users.noreply.github.com";
      extraConfig = { init = { defaultBranch = "main"; }; };
    };
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
      programs.git = {
        enable = true;
        userName = "Valarie Milton";
        userEmail = "157831739+vael3429@users.noreply.github.com";
        extraConfig = { init = { defaultBranch = "main"; }; };
      };
    };
}
