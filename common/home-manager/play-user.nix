{ pkgs, ... }: {
  home.packages = with pkgs; [
    signal-desktop
    mangohud
    protontricks
    lutris
    spotify
    android-tools
  ];
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
  # Environment variables for gaming
  home.sessionVariables = {
    MANGOHUD = "1";
    VKD3D_CONFIG = "no_upload_hvv";
  };
}
