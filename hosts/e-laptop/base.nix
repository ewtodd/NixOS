{ config, pkgs, inputs, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../common/nixos/packages.nix
    ../../common/nixos/services.nix
    ../../modules/nixos/obs.nix
    ../../modules/nixos/sway-de.nix
    ../../modules/nixos/steam.nix
  ];

  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "networkmanager"
      "wheel"
      "plugdev"
      "dialout"
      "gamemode"
      "render"
      "video"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" ];
  };

}
