{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/hardware/amd-graphics.nix
    ../../modules/nixos/desktops/desktopEnvironment.nix
    ../../modules/nixos/services/ollama.nix
    # ../../modules/nixos/services/ssh.nix
    #../../modules/nixos/services/suspend-then-hibernate.nix
    ../../modules/nixos/packages/steam.nix
    ../../modules/nixos/packages/obs.nix
    ../../modules/nixos/packages/starship.nix
    ../../modules/nixos/packages/mtkclient-udev-rules.nix
  ];

  WindowManager = "sway";
  DeviceType = "desktop";
  environment.sessionVariables = { ZK_NOTEBOOK_DIR = "$HOME/zettelkasten"; };
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
    ];
  };

  users.users.e-work = {
    isNormalUser = true;
    description = "ethan-work";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "dialout" "video" "lp" ];
  };

}
