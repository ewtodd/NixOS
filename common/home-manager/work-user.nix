{ pkgs, inputs, ... }:
let
  lisepp = pkgs.callPackage ../../modules/nixos/LISE++/default.nix { };
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
in
{
  imports = [
    ./system-options.nix
    ./xdg.nix
    ./kitty/kitty.nix
    ./fastfetch/fastfetch.nix
    ./theming/theming.nix
    ./nixvim/nixvim.nix
  ];
  home.packages = [
    pkgs.clang-tools
    pkgs.slack
    lisepp
    SRIM
    rootbrowse_package
  ];
  xdg.desktopEntries.steam = {
    name = "Steam";
    noDisplay = true;
  };
  Profile = "work";
  programs.nixvim.enable = true;
  programs.kitty = {
    enable = true;
  };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -la";
      geant4-env = "nix develop /etc/nixos/modules/dev-environments/geant4";
      analysis-env = "nix develop /etc/nixos/modules/dev-environments/analysis";
      latex-env = "nix develop /etc/nixos/modules/dev-environments/latex";
      cpp-env = "nix-shell /etc/nixos/home/e-work/cpp.nix";
      github-update = "git add . && git commit -m 'Automated commit.' && git push -u origin main";
    };
  };
  xdg.configFile = {
    "clangd/config.yaml".text = ''
      CompileFlags:
        Add: [
          "-I${pkgs.root}/include",
          "-I${pkgs.geant4}/include/Geant4"
        ]
    '';
  };
}
