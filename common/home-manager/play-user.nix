{ pkgs, ... }: {
  imports = [
    ./system-options.nix
    ./xdg/xdg.nix
    ./kitty/kitty.nix
    ./fastfetch/fastfetch.nix
    ./nix-colors/colorschemes.nix
    ./nixvim/nixvim.nix
    ./zettelkasten/zk.nix
  ];
  home.packages = with pkgs; [
    signal-desktop
    mangohud
    protontricks
    lutris
    spotify
    android-tools
  ];
  Profile = "play";
  programs.nixvim.enable = true;
  programs.kitty = { enable = true; };
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
