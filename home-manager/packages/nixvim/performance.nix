{ pkgs, ... }:
{
  performance = {
    combinePlugins = {
      enable = false;
    };

    byteCompileLua.enable = true;
    byteCompileLua.initLua = true;
    byteCompileLua.nvimRuntime = true;
  };
}
