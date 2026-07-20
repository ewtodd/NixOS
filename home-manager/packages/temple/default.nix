# Temple TUI client wrapper.
#
# Wraps the `temple` binary with TEMPLE_TOKEN loaded from the user's agenix
# secret so the client authenticates automatically. Also sets the default
# server to the public temple.ethanwtodd.com endpoint.
#
# The token file contains: TEMPLE_TOKEN=<32-char-token>
# Generated on oracle with:
#   temple-server --generate-token USERNAME PHONE
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  templePkg = inputs.temple.packages.${pkgs.stdenv.hostPlatform.system}.temple;

  # The token secret is readable by group `users` (mode 0440), so both
  # e-work and e-play (or v-work and v-play) can read the same file.
  # Try ethan's token first, then val's — whichever exists.
  templeWrapped = pkgs.writeShellScriptBin "temple" ''
    for f in /run/agenix/temple-token-ethan /run/agenix/temple-token-val; do
      if [ -r "$f" ]; then
        set -a
        . "$f"
        set +a
        break
      fi
    done
    exec ${templePkg}/bin/temple \
      --server temple.ethanwtodd.com \
      "$@"
  '';
in
{
  config = {
    home.packages = [ templeWrapped ];
  };
}
