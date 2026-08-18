{
  pkgs,
  inputs,
  ...
}:
let
  templePkg = inputs.temple.packages.${pkgs.stdenv.hostPlatform.system}.temple;

  # The daemon now runs locally on 127.0.0.1:42123 (per-user session
  # isolation via pubkey auth) — no remote endpoint, no TLS.
  templeWrapped = pkgs.writeShellScriptBin "temple" ''
    exec ${templePkg}/bin/temple --server 127.0.0.1:42123 "$@"
  '';
in
{
  config = {
    home.packages = [ templeWrapped ];
  };
}
