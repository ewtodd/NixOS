{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    displayManager.gdm.autoSuspend = false;
  };

  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    extraPackages = with pkgs; [
      # perl540Packages.Apppapersway - Enable for paper style tiling!
      birdtray
      wl-clipboard
      swaybg
      sway-contrib.grimshot
      pavucontrol
      pulseaudio
      gthumb # keep gthumb for detailed image viewing
      imagemagick # for kitty
      nautilus
      thunderbird-latest
      udiskie
      gnome-themes-extra
    ];
  };

  environment.shellAliases = { view-image = "kitten icat"; };

  security.pam.services.swaylock-effects = { };
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  programs.gnome-disks = { enable = true; };

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_THEME = "Adwaita-dark";
  };
}
