{
  "e-play" = { config, pkgs, ... }: {
    home.username = "e-play";
    home.homeDirectory = "/home/e-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/swaync/swaync.nix
      ../../modules/home-manager/kitty/kitty.nix
    ];
  };

  "e-work" = { config, pkgs, ... }: {
    home.username = "e-work";
    home.homeDirectory = "/home/e-work";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/work-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/swaync/swaync.nix
      ../../modules/home-manager/kitty/kitty.nix
    ];
  };
}
