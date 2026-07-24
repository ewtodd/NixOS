# Temple TUI client.
# The headless daemon is now a systemd system service (see
# modules/services/temple-daemon). This home-manager module only
# provides the `temple` CLI binary.
#
# Authentication uses the user's SSH public key (auto-discovered from
# ~/.ssh/id_ed25519.pub). The server verifies it against authorized_keys.
#
# Server: https://temple.ethanwtodd.com
{
  pkgs,
  inputs,
  ...
}:
let
  templePkg = inputs.temple.packages.${pkgs.stdenv.hostPlatform.system}.temple;

  templeWrapped = pkgs.writeShellScriptBin "temple" ''
    exec ${templePkg}/bin/temple \
      --server https://temple.ethanwtodd.com \
      "$@"
  '';
in
{
  config = {
    home.packages = [ templeWrapped ];
  };
}
