{ pkgs, inputs, system, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = [
      pkgs.proton-ge-custom
      inputs.nix-proton-cachyos.packages.${system}.proton-cachyos
    ];
  };
}
