{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow): Gemma 4 26B A4B and EmbeddingGemma 2 on the
# Arc A770M, on the ports maitred's gemma (8081) and embed (8082) upstreams name. The service is
# eklow's own NixOS module; this sets the model, the house's window and exposure.
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
      # Hugging Face's linked ETag for the file is its sha256.
      model = pkgs.fetchurl {
        name = "gemma-4-26b-a4b-it-qat-q4_0.gguf";
        url = "https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/d1c082be9cf3c8a514acf63b8761f4b41935842e/gemma-4-26B_q4_0-it.gguf";
        sha256 = "3eca3b8f6d7baf218a7dd6bba5fb59a56ee25fe2d567b6f5f589b4f697eca51d";
      };
      alias = "gemma-4-26b-a4b";
      # maitred lists eklow/gemma-4-26b-a4b with this window and two slots. At 2 x 262k the
      # global layers' KV takes 6.4 GiB, so each layer keeps its busiest experts on the card (51
      # of 128) by eklow's routing profile; the rest run on the CPU or stream in for prefill.
      contextSize = 262144;
      slots = 2;
      kvInt8 = true;
      extraArgs = [
        "--expert-profile"
        "${config.services.eklow.package}/share/eklow/gemma-4-26b-a4b-experts.json"
      ];
    };
  };
}
