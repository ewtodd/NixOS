{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/services/tailscale.nix
    #../../modules/nixos/services/protonvpn.nix
    ../../modules/nixos/packages/nix-mineral.nix
  ];
  DeviceType = "server";

  programs.dconf.enable = true;

  users.users.nu = {
    isNormalUser = true;
    description = "nu server";
    extraGroups = [ "networkmanager" "wheel" "dialout" "render" "video" "lp" ];
  };
}
