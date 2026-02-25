{ pkgs, ... }:
{
  performance = {
    combinePlugins = {
      enable = true;
      standalonePlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          name = "split.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "wurli";
            repo = "split.nvim";
            rev = "main";
            sha256 = "sha256-nN2hV95KCiauvDgnWtHVbvpHz2oVyCRvwWt+e02EhUA=";
          };
        })
        pkgs.vimPlugins.snacks-nvim
      ];
    };

    byteCompileLua.enable = true;
    byteCompileLua.initLua = true;
    byteCompileLua.nvimRuntime = true;
  };
}
