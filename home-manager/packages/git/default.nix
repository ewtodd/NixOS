{ osConfig, lib, ... }:
let
  isE = osConfig.systemOptions.owner.e.enable;
  isV = osConfig.systemOptions.owner.v.enable;
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name =
        if isE then
          "Ethan Todd"
        else if isV then
          "Valarie Milton"
        else
          null;
      user.email =
        if isE then
          "30243637+ewtodd@users.noreply.github.com"
        else if isV then
          "157831739+vael3429@users.noreply.github.com"
        else
          null;
      init = {
        defaultBranch = "main";
      };
      safe.directory = "/etc/nixos";
      core = {
        sharedRepository = "group";
        hooksPath = lib.mkIf isE ".githooks";
      };
      diff.tool = "nvimdiff";
      difftool.prompt = false;
      credential.helper = "store";
    };
  };
}
