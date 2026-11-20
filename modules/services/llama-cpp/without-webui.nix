# Takes a package from the llama-cpp flake input and returns it built without the bundled web UI (the servers run
# with --no-webui). The UI's npm build fails in the Nix sandbox since llama.cpp 7f106b5 (2026-11-17): both PWA
# configs copy llama-brand's favicons out of the read-only node_modules, and the second copy cannot overwrite the
# first (EACCES). useWebUi = false only stops the UI being copied into the source; the webui derivation stays an
# attribute of the package, and so a build input, until it is null.
pkg:
(pkg.override { useWebUi = false; }).overrideAttrs (
  _: oldAttrs: {
    webui = null;
    cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [ "-DLLAMA_USE_PREBUILT_UI=OFF" ];
  }
)
