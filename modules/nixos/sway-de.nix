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
    wrapperFeatures.gtk = true;
    xwayland.enable = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export XDG_CURRENT_DESKTOP="sway"
      export XDG_SESSION_TYPE="wayland"
      export LIBVA_DRIVER_NAME=iHD
      export VPL_GPU=compute-runtime  
      export MOZ_ENABLE_WAYLAND=1
      export WLR_RENDERER=vulkan
    '';
    extraOptions = [ "--verbose" "--debug" ];
    extraPackages = with pkgs; [
      birdtray
      wl-clipboard
      swayidle
      swaybg
      sway-contrib.grimshot
      swaylock-effects
      fuzzel
      pavucontrol
      pulseaudio
      gthumb
      nautilus
      thunderbird
      zathura
      udiskie
      gnome-themes-extra
    ];
  };

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
