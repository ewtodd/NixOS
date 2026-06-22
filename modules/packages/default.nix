{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let
  remarkable = inputs.remarkable.packages.${pkgs.stdenv.hostPlatform.system}.default;
  agenix = inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default;
  hasDesktop =
    config.systemOptions.deviceType.desktop.enable || config.systemOptions.deviceType.laptop.enable;
in
{
  config = lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        agenix
        claude-code
        git
        gh
        nh
        wget
        tree
        nixfmt
        nixfmt-tree
        openssl
        deadnix
        usbutils
        pciutils
        unzip
        zip
        kitty.terminfo
      ];

      virtualisation.docker.enable = lib.mkIf (config.systemOptions.apps.docker.enable) true;
    }

    (lib.mkIf hasDesktop {
      programs.steam = {
        enable = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          dwproton-bin
        ];
      };
      programs.obs-studio.enable = true;

      boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
      boot.extraModprobeConfig = ''
        options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      '';

      programs.appimage.enable = true;
      programs.appimage.binfmt = true;

      environment.systemPackages =
        with pkgs;
        [
          poppler-utils
          mpv
          wineWow64Packages.stable
          winetricks
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
    })
  ];
}
