{ pkgs, ... }: {
  home.packages = with pkgs;
    [

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
