{ ... }: {

  imports = [
    ../../common/nixos/base.nix
    ../../modules/nixos/services/tailscale.nix
    #../../modules/nixos/services/protonvpn.nix
    ../../modules/nixos/packages/nix-mineral.nix
  ];
  DeviceType = "server";
  users.users.mu = {
    isNormalUser = true;
    description = "mu server";
    extraGroups = [ "networkmanager" "wheel" "dialout" "render" "video" "lp" ];
  };
}
