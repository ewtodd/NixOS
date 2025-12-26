{ ... }:
{
  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/services/amd-graphics.nix
    ../../modules/nixos/services/openrgb.nix
    ../../modules/nixos/desktopEnvironment/desktopEnvironment.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/remarkable.nix
    ../../modules/nixos/packages/quickemu.nix
    ../../modules/nixos/packages/zoom.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/packages/docker.nix
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/sunshine.nix
    ../../modules/nixos/services/tailscale.nix
  ];

  nixpkgs.config.rocmTargets = [ "gfx1201" ];

  DeviceType = "desktop";

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
    ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
      "docker"
    ];
  };
}
