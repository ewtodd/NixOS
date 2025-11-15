{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
}
