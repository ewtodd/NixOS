{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/hardware/amd-graphics.nix
    ../../modules/nixos/hardware/suzyqable.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/services/ssh.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/sunshine.nix
    #../../modules/nixos/services/protonvpn.nix
    ../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/packages/todoist.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/freecad.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/packages/docker.nix
    ../../modules/nixos/packages/mtkclient-udev-rules.nix
    ../../modules/nixos/packages/nix-mineral.nix
  ];

  # Configure ROCm targets for RX 7900 XTX
  nixpkgs.config.rocmTargets = [ "gfx1100" ];

  WindowManager = "hyprland";
  DeviceType = "desktop";
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
      "lp"
      "tty"
      "docker"
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" "video" "lp" ];
  };

}
