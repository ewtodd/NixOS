{ lib, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/hardware/nvidia-graphics.nix
    ../../modules/nixos/hardware/openrgb.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/quickemu.nix
    ../../modules/nixos/packages/zoom.nix
    ../../modules/nixos/packages/starship.nix
  ];

  WindowManager = "cosmic";
  DeviceType = "desktop";

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
  };
}
