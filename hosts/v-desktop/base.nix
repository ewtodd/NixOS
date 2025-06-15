{ config, pkgs, inputs, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../common/nixos/packages.nix
    ../../common/nixos/services.nix
    ../../modules/nvidia.nix
    ../../modules/openrgb.nix
  ];
  programs.steam.enable = true;
  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [ "networkmanager" "wheel" "i2c"  ];
    packages = with pkgs; [ ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

}
