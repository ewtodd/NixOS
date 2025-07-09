{ pkgs, ... }: {
  home.packages = with pkgs; [

    (writeShellScriptBin "take-notes" ''
      #!/bin/bash

      # Get the current folder name (assumed to be the class name)
      CLASS_NAME=$(basename "$PWD")

      # Get the current date in the desired format
      CURRENT_DATE=$(date +"%m%d%Y")
      CURRENT_DATE_HUMAN=$(date +"%B %d %Y")

      # Create the directory with the formatted date name
      mkdir -p "''${CURRENT_DATE}"

      # Define the content of the LaTeX file
      LATEX_CONTENT="\documentclass[12pt]{article}
      \usepackage[margin=1in]{geometry}
      \usepackage{amsmath,graphicx}
      \usepackage{hyperref}
      \usepackage[version=4]{mhchem}
      \title{''${CLASS_NAME}, ''${CURRENT_DATE_HUMAN}}
      \date{\vspace{-5ex}}
      \begin{document}
      \maketitle
      \begin{section}{}
      \end{section}
      \end{document}"

      # Create the LaTeX file inside the newly created directory
      echo "$LATEX_CONTENT" > "''${CURRENT_DATE}/''${CURRENT_DATE}.tex"
      echo "LaTeX template created at '''${CURRENT_DATE}/''${CURRENT_DATE}.tex'"
    '')

    (writeShellScriptBin "update-clang" ''
      ROOT_PATH=$(${pkgs.root}/bin/root-config --incdir)
      G4_PATH=$(${pkgs.geant4}/bin/geant4-config --prefix)/include/Geant4

      CONFIG_FILE="$HOME/.config/clangd/config.yaml"

      echo "Updating clangd config with ROOT path: $ROOT_PATH"
      echo "Updating clangd config with Geant4 path: $G4_PATH"

      mkdir -p "$(dirname "$CONFIG_FILE")"

      cat << EOL > "$CONFIG_FILE"
      CompileFlags:
        Add: [
          "-I$ROOT_PATH",
          "-I$G4_PATH"
        ]
      EOL
    '')
  ];
}
