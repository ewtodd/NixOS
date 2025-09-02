{ pkgs, inputs, system, ...}: {
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-custom
      inputs.nix-proton-cachyos.packages.${system}.proton-cachyos
    ];
  };
}
