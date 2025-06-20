{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    displayManager.gdm.autoSuspend = false;
    displayManager.gdm.banner = "NO DOGS";
  };

  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    extraPackages = with pkgs; [
      birdtray
      wl-clipboard
      swaybg
      sway-contrib.grimshot
      pavucontrol
      pulseaudio
      gthumb
      nautilus
      thunderbird-latest
      zathura
      udiskie
      gnome-themes-extra
    ];
  };

  security.pam.services.swaylock-effects = { };
  services.blueman.enable = true;
  hardware.bluetooth.powerOnBoot = false;
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
