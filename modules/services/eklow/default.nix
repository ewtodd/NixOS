{
  config,
  lib,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow): Gemma 4 12B and EmbeddingGemma 2 on the Arc
# A770M, on the ports maitred's gemma (8081) and embed (8082) upstreams name. The service is
# eklow's own NixOS module; this sets the house's window and exposure.
let
  cfg = config.systemOptions.services.eklow;
in
{
  imports = [ inputs.eklow.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.eklow = {
      enable = true;
      host = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      openFirewall = cfg.lanExpose;
      # maitred lists llama/gemma-4-12b with this window and two slots.
      contextSize = 65536;
      slots = 2;
    };
  };
}
