{ lib, ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/services/laptop-power.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/starship.nix
  ];

  WindowManager = "sway";
  DeviceType = "laptop";

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
