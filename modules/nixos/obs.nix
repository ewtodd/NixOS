{ pkgs, inputs, ... }:
#let unstable = inputs.unstable.legacyPackages.${pkgs.system};
#in
{
  programs.obs-studio = {
    enable = true;
    package = pkgs.callPackage ../../packages/obs-studio/default.nix
      { }; # unstable.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };

}
