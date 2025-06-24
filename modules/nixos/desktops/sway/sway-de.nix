{ pkgs, inputs, ... }:
let unstable = inputs.unstable.legacyPackages.${pkgs.system};
in {

  imports = [ ./display-manager.nix ./misc.nix ];

  programs.sway = {
    enable = true;
    package = unstable.swayfx;
    extraPackages = with pkgs; [
      birdtray
      wl-clipboard
      swaybg
      jq
      libnotify
      sway-contrib.grimshot
      pavucontrol
      pulseaudio
      gthumb # keep gthumb for detailed image viewing
      imagemagick # for kitty
      nautilus
      thunderbird-latest
      udiskie
      gnome-themes-extra
      dracula-icon-theme
      dracula-theme
      dracula-qt5-theme
    ];
  };

}
