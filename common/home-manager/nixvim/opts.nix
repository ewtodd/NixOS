{ ... }: {
  programs.nixvim = {
    opts = {
      number = true;
      shiftwidth = 4;
      smarttab = true;
      expandtab = true;
      softtabstop = 0;
      tabstop = 8;
      clipboard = "unnamedplus";
      conceallevel = 2; # Enable concealing
      concealcursor = "nc"; # Conceal in normal and command modes
    };
  };
}
