{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  profile = config.Profile;
  lisepp = inputs.lisepp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  SRIM = inputs.SRIM.packages.${pkgs.stdenv.hostPlatform.system}.default;
  rootbrowse_bin = pkgs.writeShellScriptBin "rootbrowse_bin" ''
    exec ${pkgs.root}/bin/root --web=off -e 'new TBrowser();'  
  '';
  rootbrowse_desktop = pkgs.makeDesktopItem {
    name = "rootbrowse";
    desktopName = "rootbrowse";
    type = "Application";
    exec = "${pkgs.kitty}/bin/kitty --class floatingkitty -e ${rootbrowse_bin}/bin/rootbrowse_bin";
  };
  rootbrowse_package = pkgs.symlinkJoin {
    name = "rootbrowse";
    paths = [
      rootbrowse_bin
      rootbrowse_desktop
    ];
  };
in
{
  imports = [
    ./btop
    ./fastfetch
    ./firefox
    ./git
    ./kitty
    ./nixvim
    ./opencode
    ./shell
    ./syncthing
    ./temple
    ./zathura
  ];

  home.packages =
    with pkgs;
    [
      spotify
      libreoffice
    ]
    ++ lib.optionals (profile == "play") [
      signal-desktop
      mangohud
      gamescope
      lsfg-vk
      lsfg-vk-ui
      vulkan-tools
      android-tools
      prismlauncher
    ]
    ++ lib.optionals (profile == "work") [
      slack
      thunderbird
      lisepp
      SRIM
      rootbrowse_package
      gost
    ];
}
