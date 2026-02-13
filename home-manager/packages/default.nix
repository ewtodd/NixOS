{
  pkgs,
  lib,
  config,
  osConfig ? null,
  inputs,
  unstable,
  ...
}:
let
  profile = config.Profile;
  lisepp = inputs.lisepp.packages.${pkgs.stdenv.hostPlatform.system}.default;
  SRIM = inputs.SRIM.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
  hasAMD = if osConfig != null then (osConfig.systemOptions.graphics.amd.enable or false) else false;
  home = config.home.homeDirectory;
  wrap = inputs.nix-wrap.lib.${pkgs.stdenv.hostPlatform.system}.wrap;
  themeArgs = "-r ${home}/.config/gtk-3.0 -r ${home}/.config/gtk-4.0 -r ${home}/.config/dconf";
  wrapped-thunderbird = wrap {
    package = pkgs.thunderbird;
    executable = "thunderbird";
    wrapArgs = "-d -n -a -b -p -w ${home}/.thunderbird -w ${home}/Downloads ${themeArgs}";
  };
  wrapped-spotify = wrap {
    package = pkgs.spotify;
    executable = "spotify";
    wrapArgs = "-d -n -a -b -p -w ${home}/.config/spotify -w ${home}/.cache/spotify -r ${home}/.config/dconf";
  };
in
{
  imports = [
    ./ai
    ./fastfetch
    ./firefox
    ./git
    ./kitty
    ./nixvim
    ./shell
    ./zathura
  ];

  home.packages =
    with pkgs;
    [
      wrapped-spotify
      libreoffice
    ]
    ++ lib.optionals (profile == "play") [
      signal-desktop
      mangohud
      gamescope
      android-tools
    ]
    ++ lib.optionals (profile == "work") [
      clang-tools
      slack
      lisepp
      SRIM
      rootbrowse_package
      wrapped-thunderbird
    ];

  programs.btop = {
    enable = true;
    package = if hasAMD then unstable.btop-rocm else unstable.btop;
    settings = {
      color_theme = "TTY";
      vim_keys = true;
      proc_tree = true;
      proc_per_core = true;
      show_swap = false;
      io_mode = true;
      update_ms = 1000;
      base_10_sizes = true;
      shown_boxes = "cpu mem proc";
    };
  };
}
