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
  config,
  inputs,
  ...
}:
let
  templePkg = inputs.temple.packages.${pkgs.stdenv.hostPlatform.system}.temple;

  # Map owner → token secret name + default server
  tokenSecret =
    if config.Owner == "e" then
      config.age.secrets.temple-token-ethan.path
    else if config.Owner == "v" then
      config.age.secrets.temple-token-val.path
    else
      null;

  templeWrapped = pkgs.writeShellScriptBin "temple" ''
    if [ -r "${tokenSecret}" ]; then
      set -a
      . "${tokenSecret}"
      set +a
    fi
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
