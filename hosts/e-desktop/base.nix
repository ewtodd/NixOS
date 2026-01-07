{ ... }:
{

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/services/amd-graphics.nix
    ../../modules/nixos/services/suzyqable.nix
    ../../modules/nixos/desktopEnvironment/desktopEnvironment.nix
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/packages/docker.nix
  ];

  nixpkgs.config.rocmTargets = [ "gfx1100" ];
  powerManagement.enable = true;

  DeviceType = "desktop";
  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "gamemode"
      "render"
      "video"
      "lp"
      "tty"
      "docker"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "video"
      "lp"
    ];
  };

}
