{ pkgs, ... }: {
  home.packages = [ pkgs.clang-tools pkgs.slack ];

  xdg.desktopEntries.steam = {
    name = "Steam";
    noDisplay = true;
  };

  xdg.desktopEntries = {
    neovim = {
      name = "Neovim";
      genericName = "Text Edtior";
      exec = "foot -e nvim %F";
      terminal = false;
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ls = "ls -vAF";
      ll = "ls -l";
      rootbrowse = ''nix-shell -p root --run "rootbrowse --web=off"'';
      fix_clang = ". /etc/nixos/home/e-work/scripts/update_clang.sh";
      geant4-env = "nix-shell /etc/nixos/home/e-work/geant4.nix";
      python-env = "nix-shell /etc/nixos/home/e-work/python.nix";
      cpp-env = "nix-shell /etc/nixos/home/e-work/cpp.nix";
      github-update =
        "git add . && git commit -m 'Automated commit.' && git push -u origin main";
    };
  };

  programs.zathura.extraConfig =
    "\n        set sandbox none \n        set selection-clipboard clipboard\n  ";
}
