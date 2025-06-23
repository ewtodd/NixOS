{ pkgs, ... }: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        width = 45;
        font = "JetBrains Mono NF:weight=bold:size=16";
        terminal = "${pkgs.kitty}/bin/kitty";
        prompt = "❯ ";
      };
      colors = {
        background = "000000cc";
        selection = "c24a9bcc";
        border = "fffffffa";
      };
      border.radius = 20;
    };
  };

}
