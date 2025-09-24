{ config, pkgs, ... }:

{
  services.swayosd = {
    enable = true;
    package = pkgs.swayosd;
    # stylePath = "${config.home.homeDirectory}/.config/swayosd/style.css";
    topMargin = 0.85;
  };
}
