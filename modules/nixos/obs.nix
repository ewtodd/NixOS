{ pkgs, unstable, ... }: {
  programs.obs-studio = {
    enable = true;
    package = unstable.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };

}
