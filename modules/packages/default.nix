{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  unstable = inputs.unstable.legacyPackages.${pkgs.system};
  remarkable = inputs.remarkable.packages."x86_64-linux".default;
in
{
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.obs-studio = {
    enable = true;
    package = unstable.obs-studio;
    plugins = with pkgs.obs-studio-plugins; [ obs-backgroundremoval ];
  };
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';

  programs.starship = {
    enable = true;
    settings = {
      cmd_duration = {
        show_notifications = false;
      };
    };
  };
  programs.bash = {
    shellInit = "eval $(${pkgs.starship}/bin/starship init bash)";
  };

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
      libreoffice
      tree
      htop
      nix-prefetch-github
      nixfmt
      tree
      usbutils
      poppler-utils
      pciutils
      unzip
      wineWowPackages.stable
      winetricks
      zip
      gearlever
      imagemagick
      ghostscript
      spotify
    ]
    ++ lib.optionals (config.systemOptions.apps.zoom.enable) [ zoom-us ]
    ++ lib.optionals (config.systemOptions.apps.remarkable.enable) [ remarkable ]
    ++ lib.optionals (config.systemOptions.apps.quickemu.enable) [ quickemu ]
    ++ lib.optionals (!config.systemOptions.owner.e.enable) [
      pavucontrol
    ];

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
