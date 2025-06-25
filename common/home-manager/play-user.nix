{ pkgs, ... }: {
  imports = [
    ./xdg/xdg.nix
    ./kitty/kitty.nix
    ./fastfetch/fastfetch.nix
    ./nixvim/nixvim.nix
  ];
  home.packages = with pkgs; [
    signal-desktop
    mangohud
    protontricks
    lutris
    spotify
    android-tools
  ];
  programs.nixvim.enable = true;
  programs.nixvimProfile = "play";
  programs.kitty = {
    enable = true;
    Configuration.profile = "play";
  };
  dconf = {
    enable = true;
    settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "ls -vAF";
      ll = "ls -l";
    };
  };
  home.sessionVariables = { VKD3D_CONFIG = "no_upload_hvv"; };
}
