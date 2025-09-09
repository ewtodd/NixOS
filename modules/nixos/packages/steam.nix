{ pkgs, inputs, system, ...}: {
  nixpkgs.config.allowUnfree = true;
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      inputs.nix-proton-cachyos.packages.${system}.proton-cachyos
    ];
  };
}
