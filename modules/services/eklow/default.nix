{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow): Ornith-1.5-35B-A3B (a Qwen3.6-35B-A3B finetune) with DFlash 2
# speculative decoding, and EmbeddingGemma 2, on the Arc A770M, on the ports maitred's eklow (8081) and embed (8082)
# upstreams name. The service is eklow's own NixOS module; this sets the model, the house's window and exposure.
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
      # Hugging Face's linked ETag for a file is its sha256. eklow's own mix (routed experts Q4_K, everything else Q8_0,
      # head Q6_K; DECISIONS 2026-10-31), with Ornith's own chat template, which the server recognizes.
      model = pkgs.fetchurl {
        name = "Ornith-1.5-35B-A3B-Q4_K-Q8_0.gguf";
        url = "https://huggingface.co/ethanwtodd/Ornith-1.5-35B-A3B-Q4_K-Q8_0-GGUF/resolve/a89886e005b293b16039dc56b6cf525112d69340/Ornith-1.5-35B-A3B-Q4_K-Q8_0.gguf";
        sha256 = "25a681297b42b5e5c0088d01fb1116148ce4eced2fe8dd5792bf03022eefa1a3";
      };
      alias = "ornith-1.5-35b-a3b";
      expertProfile = "${config.services.eklow.package}/share/eklow/ornith-1.5-experts.json";
      # Inco AI's DFlash 2 draft (for Qwen3.6; on Ornith it ties the Ornith-trained one at the short blocks this card
      # runs), lossless; verify blocks of 4 by default.
      draft = pkgs.fetchurl {
        name = "Qwen3.6-35B-A3B-DFlash2-Q8_0.gguf";
        url = "https://huggingface.co/ethanwtodd/Qwen3.6-35B-A3B-DFlash2-Q8_0-GGUF/resolve/65aaab9513e9c6608ada7c7d16e6532c198a2296/Qwen3.6-35B-A3B-DFlash2-Q8_0.gguf";
        sha256 = "986b8f24ac3469ed122946fb5be5b1fbe186467f2573f84e48bdbf7db278b327";
      };
      # Qwen3-VL's vision encoder for image parts in chat (bartowski's projector, tensor-identical to eklow's own
      # conversion; stock Qwen3.6's tower is the same): 267 MiB on the card while it encodes, up to 1024 rows an image.
      mmproj = pkgs.fetchurl {
        name = "mmproj-Ornith-1.5-35B-A3B-bf16.gguf";
        url = "https://huggingface.co/bartowski/Ornith-1.5-35B-A3B-GGUF/resolve/64b0493d34a5ca4c1b4ad67bb99b41d74b4f07d6/mmproj-Ornith-1.5-35B-A3B-bf16.gguf";
        sha256 = "eef27583f74f2990b7a3d97119a0b67c05aeb48c92dde9466f050e30bf1a3595";
      };
      # Image inputs to /v1/embeddings.
      embedMmproj = pkgs.fetchurl {
        name = "mmproj-embeddinggemma-2-Q8_0.gguf";
        url = "https://huggingface.co/ggml-org/embeddinggemma-2-GGUF/resolve/58faf90940886df2d62be555c8765d00dac362c5/mmproj-embeddinggemma-2-Q8_0.gguf";
        sha256 = "c4a8a52691ecef40618438928bdf9e68379b854e24166f292592353db0aab64f";
      };
      # maitred lists eklow/ornith-1.5-35b-a3b with this window and two slots. The 10 attention layers' K/V take 5.8 GiB
      # at 2 x 262k, so beside the draft and the two image encoders each layer keeps its 51 busiest of 256 experts on
      # the card by the routing profile; the rest run on the CPU (~13 GiB pinned) or stream in for prefill.
      contextSize = 262144;
      slots = 2;
      kvInt8 = true;
    };
  };
}
