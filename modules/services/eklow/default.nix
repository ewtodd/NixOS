{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow) on the Arc A770M: one engine, two chat models as instances, each with
# EmbeddingGemma 2 beside it. `ornith` (eklow-ornith.service; the name kept from the model it served until 2026-11-07)
# serves InternScience's Sage-A1.5 (a Qwen3.6-35B-A3B finetune) with DFlash 2 speculative decoding on the port maitred's eklow upstream names (8081); `gemma` (eklow-gemma.service)
# serves Gemma 4 26B A4B on eklow-gemma's (8083). Both serve the embeddings on embed's (8082). The card holds one at a
# time: `llm-mode ornith|gemma` switches (modules/services/llm-mode). The service is eklow's own NixOS module; this
# sets the models, the house's window and exposure.
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
      # eklow built on its own nixpkgs (intel-llvm 7.1.1), the toolchain its checks ran on: built with the fleet's
      # (7.2.0, 2026-11-02) the server finds 0.8 GiB less card memory free after loading, keeps 39 experts a layer
      # on the card instead of 51 and runs 6-9% slower.
      package = inputs.eklow.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # Image inputs to /v1/embeddings.
      embedMmproj = pkgs.fetchurl {
        name = "mmproj-embeddinggemma-2-Q8_0.gguf";
        url = "https://huggingface.co/ggml-org/embeddinggemma-2-GGUF/resolve/58faf90940886df2d62be555c8765d00dac362c5/mmproj-embeddinggemma-2-Q8_0.gguf";
        sha256 = "c4a8a52691ecef40618438928bdf9e68379b854e24166f292592353db0aab64f";
      };

      instances.ornith = {
        # Sage-A1.5 in place of Ornith-1.5 since 2026-11-07 (eklow DECISIONS "Sage-A1.5 on eklow": on fiona's replay it never
        # thought itself into the token cap where Ornith did 6 times in 18, and writes about a third of the tokens).
        # Hugging Face's linked ETag for a file is its sha256. eklow's own mix (routed experts Q4_K, everything else Q8_0,
        # head Q6_K), made from InternScience's Q8_0, with Sage's own chat template, which the server recognizes.
        model = pkgs.fetchurl {
          name = "Sage-A1.5-Q4_K-Q8_0.gguf";
          url = "https://huggingface.co/ethanwtodd/Sage-A1.5-Q4_K-Q8_0-GGUF/resolve/d89116d892ff239ae008ce3a3022ae2e9d9d561c/Sage-A1.5-Q4_K-Q8_0.gguf";
          sha256 = "6d25f1417713e555aa5b731ab1cac37fe08a66bd1d0ed028476a7df3e8a46f0e";
        };
        alias = "sage-a1.5";
        port = 8081;
        # Sage has no routing profile of its own; stock Qwen3.6's, which it was finetuned from.
        expertProfile = "${config.services.eklow.package}/share/eklow/qwen36-experts.json";
        # Sage's verification protocol on for conversations with a system message (a request may send its own).
        verification = true;
        # Inco AI's DFlash 2 draft (for Qwen3.6), lossless; verify blocks of 4 by default. On Sage it accepts 11-30% more
        # than Sage's own MTP head (eklow DECISIONS 2026-11-07).
        draft = pkgs.fetchurl {
          name = "Qwen3.6-35B-A3B-DFlash2-Q8_0.gguf";
          url = "https://huggingface.co/ethanwtodd/Qwen3.6-35B-A3B-DFlash2-Q8_0-GGUF/resolve/65aaab9513e9c6608ada7c7d16e6532c198a2296/Qwen3.6-35B-A3B-DFlash2-Q8_0.gguf";
          sha256 = "986b8f24ac3469ed122946fb5be5b1fbe186467f2573f84e48bdbf7db278b327";
        };
        # Qwen3-VL's vision encoder for image parts in chat (bartowski's projector, tensor-identical to eklow's own
        # conversion; stock Qwen3.6's tower is the same, and so is Sage's, within F16 rounding): 267 MiB on the card while it encodes, up to 1024 rows an image.
        mmproj = pkgs.fetchurl {
          name = "mmproj-Ornith-1.5-35B-A3B-bf16.gguf";
          url = "https://huggingface.co/bartowski/Ornith-1.5-35B-A3B-GGUF/resolve/64b0493d34a5ca4c1b4ad67bb99b41d74b4f07d6/mmproj-Ornith-1.5-35B-A3B-bf16.gguf";
          sha256 = "eef27583f74f2990b7a3d97119a0b67c05aeb48c92dde9466f050e30bf1a3595";
        };
        # maitred lists eklow/sage-a1.5 with this window and two slots. The two slots share one pool of 262k positions'
        # K/V (3.0 GiB instead of 5.8 for 2 x 262k; each slot may still hold 262k, and when the pool runs out an idle
        # slot gives its pages back and re-prefills later): beside the draft and the two image encoders each layer keeps
        # its 91 busiest of 256 experts on the card instead of 48, decode +22% at 8k; the rest run on the CPU or stream
        # in for prefill.
        contextSize = 262144;
        slots = 2;
        kvPool = 262144;
        kvInt8 = true;
        snapshotMiB = 4096;
        prefillGroup = 8;
        prefillGroupBusy = 4096;
      };

      instances.gemma = {
        # Google's QAT Q4_0, as served 2026-10-27 to 2026-11-02.
        model = pkgs.fetchurl {
          name = "gemma-4-26b-a4b-it-qat-q4_0.gguf";
          url = "https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/d1c082be9cf3c8a514acf63b8761f4b41935842e/gemma-4-26B_q4_0-it.gguf";
          sha256 = "3eca3b8f6d7baf218a7dd6bba5fb59a56ee25fe2d567b6f5f589b4f697eca51d";
        };
        alias = "gemma-4-26b-a4b";
        port = 8083;
        expertProfile = "${config.services.eklow.package}/share/eklow/gemma-4-26b-a4b-experts.json";
        # Image parts in chat: the 26B's own gemma4v encoder (its card memory, with EmbeddingGemma 2's, costs the 26B
        # five experts a layer).
        mmproj = pkgs.fetchurl {
          name = "gemma-4-26b-a4b-it-mmproj.gguf";
          url = "https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/d1c082be9cf3c8a514acf63b8761f4b41935842e/gemma-4-26B-it-mmproj.gguf";
          sha256 = "a359953a076b877db30c31dbbb4c6d93b4a6e017ee5db5784247e4d4c0dd4f3b";
        };
        # maitred lists eklow/gemma-4-26b-a4b with this window and two slots. At 2 x 262k the global layers' KV takes
        # 6.4 GiB, so each layer keeps its busiest experts on the card (44 of 128 with the image encoders) by the
        # routing profile; the rest run on the CPU or stream in for prefill.
        contextSize = 262144;
        slots = 2;
        kvInt8 = true;
      };
    };
  };
}
