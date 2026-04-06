{
  lib,
  osConfig,
  ...
}:
{
  config = lib.mkIf (osConfig.systemOptions.owner.e.enable) {
    services.syncthing = {
      enable = true;
      overrideDevices = false;
      overrideFolders = false;
    };

    home.activation.createOrgDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ~/org
      [ -f ~/org/refile.org ] || touch ~/org/refile.org
    '';
  };
}
