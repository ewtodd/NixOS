{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/hardware/laptop-power.nix
    ../../modules/nixos/desktops/desktopEnvironment-darkviolet.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/quickemu.nix
    ../../modules/nixos/packages/zoom.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/services/fingerprint.nix
    ../../modules/nixos/packages/docker.nix
    ../../modules/nixos/packages/moonlight.nix
  ];

  WindowManager = "sway";
  DeviceType = "laptop";

  users.users.v-play = {
    isNormalUser = true;
    description = "v-play";
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" ];
  };
  users.users.v-work = {
    isNormalUser = true;
    description = "v-work";
    extraGroups = [ "networkmanager" "wheel" "i2c" "docker" ];
  };
}
