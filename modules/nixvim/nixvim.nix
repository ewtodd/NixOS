{ config, pkgs, ... }: {
  imports = [
    ./colorschemes.nix
    ./keymaps.nix
    ./opts.nix
    ./performance.nix
    ./plugins.nix
  ];
  programs.nixvim.enable = true;
}
