{ config, lib, pkgs, ... }: {
  programs.nixvim.colorschemes.dracula = {
    enable = true;
    settings.colorterm = false;
  };
}
