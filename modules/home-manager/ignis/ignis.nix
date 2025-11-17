{ inputs, ... }:
let ignis = inputs.ignis.packages."x86_64-linux".default;
in {
  programs.ignis = {
    enable = true;
    package = ignis;
    #    configDir = ./ignis-conf;

    services = {
      bluetooth.enable = true;
      recorder.enable = true;
      audio.enable = true;
      network.enable = true;
    };

    sass = {
      enable = true;
      useDartSass = true;
    };
  };
}
