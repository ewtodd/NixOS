{ ... }:
{

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/desktopEnvironment/desktopEnvironment.nix
    ../../modules/nixos/services/fwupdmgr.nix
    ../../modules/nixos/services/suzyqable.nix
    ../../modules/nixos/services/laptop-power.nix
    ../../modules/nixos/services/chromebook-audio.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/starship.nix
  ];

  DeviceType = "laptop";
  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups = [
      "networkmanager"
      "wheel"
      "dialout"
      "render"
      "video"
      "lp"
      "tss"
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
      "tss"
    ];
  };

}
