{ config, pkgs, ... }: {
  programs.nixvim.performance = {
    combinePlugins.enable = true;
    byteCompileLua.enable = true;
    byteCompileLua.initLua = true;
    byteCompileLua.nvimRuntime = true;
  };
}
