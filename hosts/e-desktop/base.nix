{ config, pkgs, inputs, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../common/nixos/packages.nix
    ../../common/nixos/services.nix
    ../../modules/nixos/hardware/intel-graphics.nix
    ../../modules/nixos/desktops/sway/sway-de.nix
    # ../../modules/nixos/services/ssh.nix
    #../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/starship.nix
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
    extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" "video" ];
  };

}
