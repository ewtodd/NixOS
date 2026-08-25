{
  pkgs,
  lib,
  inputs,
  config,
  osConfig,
  ...
}:
let
  soa = osConfig.systemOptions.services.son-of-anton;

  # The master key is the users-group agenix secret already sourced by the
  # opencode wrapper (`LITELLM_MASTER_KEY=...` on one line). The repo module's
  # activation concatenates environmentFiles into ~/.son-of-anton/.env at
  # activation time — a runtime read, so the key never lands in the store.
  soaEnvFiles = [ "/run/agenix/litellm-master-key" ];
in
{
  imports = [ inputs.son-of-anton.homeManagerModules.default ];

  config = lib.mkIf soa.interactive.enable {
    services.son-of-anton = {
      enable = true;
      # The always-on gateway is the SYSTEM service under the son-of-anton
      # account (systemOptions.services.son-of-anton). Interactive accounts
      # only get the CLI + their own per-user state.
      gateway.enable = false;
      settings = lib.recursiveUpdate soa.settings soa.interactive.settings;
      environmentFiles = soaEnvFiles;
    };
  };
}
