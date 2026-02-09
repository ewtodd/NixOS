{ osConfig, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.name = if (osConfig.systemOptions.owner.e.enable) then "Ethan Todd" else "Valarie Milton";
      user.email =
        if (osConfig.systemOptions.owner.e.enable) then
          "30243637+ewtodd@users.noreply.github.com"
        else
          "157831739+vael3429@users.noreply.github.com";
      init = {
        defaultBranch = "main";
      };
      safe.directory = "/etc/nixos";
      core.sharedRepository = "group";
      credential.helper = "store";
    };
  };
}
