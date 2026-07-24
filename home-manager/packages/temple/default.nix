# Temple TUI client and headless daemon.
#
# Authentication uses the user's SSH public key (auto-discovered from
# ~/.ssh/id_ed25519.pub). The server verifies it against authorized_keys.
#
# Server: https://temple.ethanwtodd.com
{
  pkgs,
  lib,
  config,
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

  daemonCwd =
    if config.home.username == "e-play" then "/home/e-play/Software" else config.home.homeDirectory;
in
{
  config = lib.mkMerge [
    {
      home.packages = [ templeWrapped ];
    }
    {
      systemd.user.services.temple-daemon = {
        Unit = {
          Description = "temple headless client daemon — executes tool requests locally";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${templeWrapped}/bin/temple --daemon --cwd ${daemonCwd} --mode yolo --identity %h/.ssh/id_ed25519";
          Restart = "always";
          RestartSec = "10s";
          Environment = "HOME=%h";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    }
  ];
}
