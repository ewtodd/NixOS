{
  "v-play" = { inputs, ... }: {
    home.username = "v-play";
    home.homeDirectory = "/home/v-play";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/play-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/niri/niri.nix
    ];
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      settings = {
        user.name = "Valarie Milton";
        user.email = "157831739+vael3429@users.noreply.github.com";
        init = { defaultBranch = "main"; };
        safe.directory = "/etc/nixos";
        core.sharedRepository = "group";
      };
    };
    WallpaperPath = "/etc/nixos/hosts/v-desktop/play.png";
    colorScheme = inputs.nix-colors.colorSchemes.eris;
  };

  "v-work" = { pkgs, inputs, ... }: {
    home.username = "v-work";
    home.homeDirectory = "/home/v-work";
    home.stateVersion = "25.05";
    imports = [
      ../../common/home-manager/work-user.nix
      ../../modules/home-manager/waybar/waybar.nix
      ../../modules/home-manager/niri/niri.nix
    ];
    home.packages = [ pkgs.signal-desktop ];
    programs.waybar.enable = true;
    programs.git = {
      enable = true;
      settings = {
        user.name = "Valarie Milton";
        user.email = "157831739+vael3429@users.noreply.github.com";
        init = { defaultBranch = "main"; };
        safe.directory = "/etc/nixos";
        core.sharedRepository = "group";
      };
    };
    WallpaperPath = "/etc/nixos/hosts/v-desktop/work.png";
    colorScheme = inputs.nix-colors.colorSchemes.atelier-cave;
  };

  "root" = { ... }: {
    home.username = "root";
    home.stateVersion = "25.05";
    imports = [ ../../common/home-manager/root-user.nix ];
  };

}
