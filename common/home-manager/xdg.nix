{ ... }: {
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Text and code files (nvim via kitty)
      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "text/x-readme" = "nvim.desktop";
      "text/x-log" = "nvim.desktop";
      "text/css" = "nvim.desktop";
      "text/javascript" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-shellscript" = "nvim.desktop";
      "text/x-csrc" = "nvim.desktop";
      "text/x-chdr" = "nvim.desktop";
      "text/x-c++src" = "nvim.desktop";
      "text/x-c++hdr" = "nvim.desktop";
      "text/x-rust" = "nvim.desktop";
      "text/x-go" = "nvim.desktop";
      "application/x-yaml" = "nvim.desktop";
      "application/toml" = "nvim.desktop";

      # PDF files (zathura via kitty)
      "application/pdf" = "org.pwmt.zathura.desktop";

      # Image files (gthumb)
      "image/jpeg" = "org.gnome.gThumb.desktop";
      "image/jpg" = "org.gnome.gThumb.desktop";
      "image/png" = "org.gnome.gThumb.desktop";
      "image/gif" = "org.gnome.gThumb.desktop";
      "image/webp" = "org.gnome.gThumb.desktop";
      "image/bmp" = "org.gnome.gThumb.desktop";
      "image/tiff" = "org.gnome.gThumb.desktop";
      "image/svg+xml" = "org.gnome.gThumb.desktop";
      "image/avif" = "org.gnome.gThumb.desktop";

      # File/directory browsing (nautilus)
      "inode/directory" = "org.gnome.Nautilus.desktop";

      # Archives (file-roller is common with nautilus, or specify your preference)
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-xz-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/gzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";

      # Web browser (add firefox or your preferred browser)
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/ftp" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
      # LibreOffice Writer (documents)
      "application/vnd.oasis.opendocument.text" = "writer.desktop"; # .odt
      "application/vnd.oasis.opendocument.text-template" =
        "writer.desktop"; # .ott
      "application/msword" = "writer.desktop"; # .doc
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "writer.desktop"; # .docx
      "application/rtf" = "writer.desktop"; # .rtf
      "text/rtf" = "writer.desktop";

      # LibreOffice Calc (spreadsheets)
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop"; # .ods
      "application/vnd.oasis.opendocument.spreadsheet-template" =
        "calc.desktop"; # .ots
      "application/vnd.ms-excel" = "calc.desktop"; # .xls
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
        "calc.desktop"; # .xlsx
      "application/vnd.ms-excel.sheet.macroEnabled.12" = "calc.desktop"; # .xlsm
      "text/csv" = "calc.desktop"; # .csv

      # LibreOffice Impress (presentations)
      "application/vnd.oasis.opendocument.presentation" =
        "impress.desktop"; # .odp
      "application/vnd.oasis.opendocument.presentation-template" =
        "impress.desktop"; # .otp
      "application/vnd.ms-powerpoint" = "impress.desktop"; # .ppt
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
        "impress.desktop"; # .pptx

      # LibreOffice Draw (drawings)
      "application/vnd.oasis.opendocument.graphics" = "draw.desktop"; # .odg
      "application/vnd.oasis.opendocument.graphics-template" =
        "draw.desktop"; # .otg
    };
  };
}
