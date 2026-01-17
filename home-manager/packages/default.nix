{
  pkgs,
  lib,
  config,
  osConfig,
  inputs,
  ...
}:
let
  profile = config.Profile;
  lisepp = inputs.lisepp.packages."x86_64-linux".default;
  SRIM = inputs.SRIM.packages."x86_64-linux".default;
  rootbrowse_bin = pkgs.writeShellScriptBin "rootbrowse_bin" "${pkgs.root}/bin/rootbrowse --web=off";
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
  zoombrowse_bin = pkgs.writeShellScriptBin "zoombrowse_bin" "${pkgs.firefox}/bin/firefox --private-window zoom.us & disown";
  zoombrowse_desktop = pkgs.makeDesktopItem {
    name = "zoom";
    desktopName = "zoom";
    type = "Application";
    exec = "${zoombrowse_bin}/bin/zoombrowse_bin";
  };
  zoombrowse_package = pkgs.symlinkJoin {
    name = "zoombrowse";
    paths = [
      zoombrowse_bin
      zoombrowse_desktop
    ];
  };
in
{
  imports = [
    ./fastfetch
    ./git
    ./kitty
    ./nixvim
    ./qutebrowser
    ./zathura
  ];

  home.packages =
    with pkgs;
    [ ]
    ++ lib.optionals (profile == "play") [
      signal-desktop
      mangohud
      android-tools
      mumble
    ]
    ++ lib.optionals (profile == "work") [
      pkgs.clang-tools
      pkgs.slack
      lisepp
      SRIM
      rootbrowse_package
    ]
    ++ lib.optionals (profile == "work" && osConfig.systemOptions.owner.e.enable) [
      zoombrowse_package
    ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -l";
      vpn =
        lib.mkIf (profile == "work" && osConfig.systemOptions.owner.e.enable)
          ''sudo openconnect --protocol=anyconnect --authgroup="UMVPN-Only U-M Traffic alt" umvpn.umnet.umich.edu'';
      phone-home = lib.mkIf (
        osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.laptop.enable
      ) "ssh ${config.home.username}@ssh.ethanwtodd.com -p 2222";
      files-home = lib.mkIf (
        osConfig.systemOptions.owner.e.enable && osConfig.systemOptions.deviceType.laptop.enable
      ) "sftp -P 2222 ${config.home.username}@ssh.ethanwtodd.com";

    };
  };
}
