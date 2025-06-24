{
  "e-play" = { config, pkgs, ... }: {
    home.username = "e-play";
    home.homeDirectory = "/home/e-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/waybar/waybar-sway.nix
      ../../modules/home-manager/swaync/swaync.nix
      ../../modules/home-manager/sway/sway.nix
      ../../modules/home-manager/sway/settings/play.nix
      ../../modules/home-manager/sway/settings/desktop.nix
    ];
  };

  "e-work" = { config, pkgs, ... }: {
    home.username = "e-work";
    home.homeDirectory = "/home/e-work";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/work-user.nix
      ../../modules/home-manager/waybar/waybar-sway.nix
      ../../modules/home-manager/swaync/swaync.nix
      ../../modules/home-manager/sway/sway.nix
      ../../modules/home-manager/sway/settings/work.nix
      ../../modules/home-manager/sway/settings/desktop.nix
    ];
  };
}
