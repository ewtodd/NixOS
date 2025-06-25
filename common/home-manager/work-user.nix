{ pkgs, ... }: {
  imports = [
    ./system-options.nix
    ./xdg/xdg.nix
    ./kitty/kitty.nix
    ./fastfetch/fastfetch.nix
    ./nix-colors/colorschemes.nix
    ./nixvim/nixvim.nix
  ];
  home.packages = [ pkgs.clang-tools pkgs.slack ];

  xdg.desktopEntries.steam = {
    name = "Steam";
    noDisplay = true;
  };
  Profile = "work";
  programs.nixvim.enable = true;
  programs.kitty = { enable = true; };
  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "ls -vAF";
      ll = "ls -la";
      rootbrowse = ''nix-shell -p root --run "rootbrowse --web=off"'';
      fix_clang = ". /etc/nixos/home/e-work/scripts/update_clang.sh";
      geant4-env = "nix-shell /etc/nixos/home/e-work/geant4.nix";
      analysis-env =
        "nix-shell /etc/nixos/modules/dev-environments/analysis.nix";
      cpp-env = "nix-shell /etc/nixos/home/e-work/cpp.nix";
      github-update =
        "git add . && git commit -m 'Automated commit.' && git push -u origin main";
    };
  };
}
