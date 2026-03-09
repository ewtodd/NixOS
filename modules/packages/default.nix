{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  remarkable = inputs.remarkable.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs.steam = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
  };

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  virtualisation.docker.enable = true;
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  environment.systemPackages =
    with pkgs;
    [
      git
      gh
      nh
      wget
      tree
      nixfmt
      tree
      usbutils
      poppler-utils
      mpv
      pciutils
      unzip
      wineWow64Packages.stable
      winetricks
      zip
      gearlever
      imagemagick
      ghostscript
      pavucontrol
      waypipe
    ]
    ++ lib.optionals (config.systemOptions.apps.zoom.enable) [ zoom-us ]
    ++ lib.optionals (config.systemOptions.apps.remarkable.enable) [ remarkable ]
    ++ lib.optionals (config.systemOptions.apps.quickemu.enable) [ quickemu ];

  environment.shellAliases = lib.mkIf (config.systemOptions.apps.quickemu.enable) {
    windows = "quickemu --vm /home/v-work/.config/qemu/windows-11.conf";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.ubuntu
    fira-code
    fira-code-symbols
  ];
}
