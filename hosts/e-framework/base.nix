{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/hardware/suzyqable.nix
    ../../modules/nixos/hardware/chromebook-audio.nix
    ../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/services/laptop-power.nix
    ../../modules/nixos/services/tailscale.nix
    #../../modules/nixos/services/protonvpn.nix
    ../../modules/nixos/packages/moonlight.nix
    ../../modules/nixos/packages/todoist.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/freecad.nix
    ../../modules/nixos/packages/blender.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/packages/mtkclient-udev-rules.nix
    ../../modules/nixos/packages/nix-mineral.nix
  ];
  WindowManager = "hyprland";
  DeviceType = "framework";
  users.users.e-play = {
    isNormalUser = true;
    description = "ethan-play";
    extraGroups =
      [ "networkmanager" "wheel" "dialout" "gamemode" "render" "video" "lp" ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [ "networkmanager" "wheel" "dialout" "video" "lp" ];
  };

}
