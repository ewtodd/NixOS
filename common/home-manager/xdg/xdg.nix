{ pkgs, config, ... }: {
  xdg.desktopEntries = {
    neovim = {
      name = "Neovim";
      genericName = "Text Edtior";
      exec = "kitty -e nvim %F";
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

  #  xdg.desktopEntries.fancy-cat = {
  #   name = "fancy-cat";
  #  genericName = "Terminal PDF Viewer";
  #  comment = "PDF viewer for terminal using Kitty image protocol";
  # exec = "kitty fancy-cat %f";
  #icon = "application-pdf";
  # type = "Application";
  # terminal = false;
  # categories = [ "Office" "Viewer" ];
  # mimeType = [ "application/pdf" ];
  # };

  #  xdg.mimeApps = {
  #   enable = true;
  #   defaultApplications = { "application/pdf" = "fancy-cat.desktop"; };
  #};
}
