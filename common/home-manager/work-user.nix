{ pkgs, ... }: {
  imports = [
    ./system-options.nix
    ./kitty/kitty.nix
    ./ranger/ranger.nix
    ./fastfetch/fastfetch.nix
    ./theming/theming.nix
    ./nixvim/nixvim.nix
    ./scripts/work-scripts.nix
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
      fix-clang = "update-clang";
      geant4-env = "nix-shell /etc/nixos/home/e-work/geant4.nix";
      analysis-env = "nix develop /etc/nixos/modules/dev-environments/analysis";
      latex-env = "nix develop /etc/nixos/modules/dev-environments/latex";
      cpp-env = "nix-shell /etc/nixos/home/e-work/cpp.nix";
      github-update =
        "git add . && git commit -m 'Automated commit.' && git push -u origin main";
    };
  };
}
