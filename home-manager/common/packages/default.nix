{
  pkgs,
  lib,
  config,
  osConfig ? null,
  inputs,
  ...
}:
let
  profile = config.Profile;
  isLinux = pkgs.stdenv.isLinux;
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
  unstable = inputs.unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Safely access osConfig
  hasAMD = if osConfig != null then (osConfig.systemOptions.graphics.amd.enable or false) else false;
in
{
  imports = [
    ./ai
    ./fastfetch
    ./git
    ./kitty
    ./nixvim
    ./shell
    ./zathura
  ];

  home.packages =
    with pkgs;
    [ ]
    ++ lib.optionals (isLinux && profile == "play") [
      signal-desktop
      mangohud
      gamescope
      android-tools
      mumble
    ]
    ++ lib.optionals (isLinux && profile == "work") [
      pkgs.clang-tools
      pkgs.slack
      lisepp
      SRIM
      rootbrowse_package
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
