{ config, pkgs, inputs, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../common/nixos/packages.nix
    ../../common/nixos/services.nix
    ../../modules/nixos/nvidia-graphics.nix
    ../../modules/nixos/openrgb.nix
    ../../modules/nixos/cosmic-de.nix
    ../../modules/nixos/obs.nix
    ../../modules/nixos/steam.nix
    ../../modules/nixos/quickemu.nix
    ../../modules/nixos/zoom.nix
  ];
  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
