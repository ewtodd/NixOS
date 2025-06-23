{ pkgs, inputs, ... }: {
  programs.obs-studio = {
    enable = true;
    package =
      pkgs.qt6Packages.callPackage ../../packages/obs-studio/default.nix { };
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };

}
