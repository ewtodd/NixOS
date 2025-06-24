{ pkgs, ... }: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        width = 80;
        lines = 15;
        font = "JetBrains Mono NF:weight=bold:size=14";
        terminal = "${pkgs.kitty}/bin/kitty";
        prompt = "❯ ";
        horizontal-pad = 20;
        vertical-pad = 10;
        inner-pad = 5;
      };
      colors = {
        background = "282a36bf";
        text = "f8f8f2ff";
        selection = "44475aff";
        selection-text = "f8f8f2ff";
        border = "6272a4ff";
        match = "ffb86cff";
        prompt = "ff79c6ff";
      };
      border = {
        radius = 12;
        width = 1;
      };
    };
  };
  _module.args.launcherCommand = "fuzzel";
}
