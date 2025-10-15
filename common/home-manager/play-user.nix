{ pkgs, ... }: {
  imports = [
    ./system-options.nix
    ./xdg.nix
    ./kitty/kitty.nix
    ./ranger/ranger.nix
    ./fastfetch/fastfetch.nix
    ./theming/theming.nix
    ./nixvim/nixvim.nix
  ];
  home.packages = with pkgs; [
    signal-desktop
    mangohud
    protontricks
    lutris
    spotify
    android-tools
    mumble
  ];
  Profile = "play";
  programs.nixvim.enable = true;
  programs.kitty = { enable = true; };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = { ll = "ls -l"; };
  };
  home.sessionVariables = { VKD3D_CONFIG = "no_upload_hvv"; };
}
