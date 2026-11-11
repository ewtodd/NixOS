{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow) on the Arc A770M: one engine, its chat models as instances. Whichever
# instance runs also serves EmbeddingGemma 2 (embed's port, 8082), son-of-anton's end-of-turn checker (8084) and
# Qwen3-Reranker (8085). `bolt` (eklow-bolt.service) serves NVIDIA's Nemotron-3.5-Bolt-E4B on the port maitred's eklow
# upstream names (8081), fiona's chat model since 2026-11-11; `sage` (InternScience's Sage-A1.5, a Qwen3.6-35B-A3B
# finetune, before it) stays an `llm-mode` to switch to, on 8086 (modules/services/llm-mode); the card holds one
# instance at a time. The service is eklow's own NixOS module; this sets the models, the house's window and exposure.
let
  cfg = config.systemOptions.services.eklow;
  eklowPkgs = inputs.eklow.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.eklow.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.eklow = {
      enable = true;
      host = if cfg.lanExpose then "0.0.0.0" else "127.0.0.1";
      # eklow built on its own nixpkgs (intel-llvm 7.1.1), the toolchain its checks ran on: built with the fleet's
      # (7.2.0, 2026-11-02) the server finds 0.8 GiB less card memory free after loading, keeps 39 experts a layer
      # on the card instead of 51 and runs 6-9% slower.
      package = eklowPkgs.default;
      # Image inputs to /v1/embeddings.
      embedMmproj = pkgs.fetchurl {
        name = "mmproj-embeddinggemma-2-Q8_0.gguf";
        url = "https://huggingface.co/ggml-org/embeddinggemma-2-GGUF/resolve/58faf90940886df2d62be555c8765d00dac362c5/mmproj-embeddinggemma-2-Q8_0.gguf";
        sha256 = "c4a8a52691ecef40618438928bdf9e68379b854e24166f292592353db0aab64f";
      };

      instances.bolt = {
        # eklow's derivations pin each file (eklow nix/models.nix): NVIDIA's Q4_K_M, Gemma 4 E4B's projector (Bolt's vision
        # tower is Google's, tensor for tensor) and NVIDIA's DFlash draft quantized to Q8_0 at build time. On fiona's replay
        # it scores 30-31 of 54 against llama.cpp's 32 with the same sampler (eklow DECISIONS 2026-11-11).
        model = eklowPkgs.bolt-e4b;
        alias = "nemotron-3.5-bolt-e4b";
        port = 8081;
        slots = 2;
        contextSize = 65536;
        # fp16 K/V, set rather than left to the server's per-model default so a change there cannot make it int8: the
        # two 64K slots take 2.2 GiB, and all of this instance's models fit in 12.7 of the card's 16 GiB.
        kvInt8 = false;
        draft = eklowPkgs.bolt-e4b-dflash;
        mmproj = eklowPkgs.bolt-e4b-mmproj;
        # Bolt's template drops earlier turns' reasoning, so the user message after a tool loop prefilled the loop again:
        # 0.4-15 s to the first token on fiona's chats, 0.2-1.3 s with this (eklow DECISIONS 2026-11-11). The window then
        # fills 1.2-1.7x faster; whether answers change is not measured yet.
        preserveThinking = true;
      };

      instances.sage = {
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
        port = 8086;
        # Sage has no routing profile of its own; stock Qwen3.6's, which it was finetuned from.
        expertProfile = "${config.services.eklow.package}/share/eklow/qwen36-experts.json";
        # Sage's verification protocol on for conversations with a system message (a request may send its own).
        verification = true;
        # Keep earlier turns' reasoning in the prompt, as Ornith's template always did. Sage's (stock's) template drops it at
        # every new user message, so the whole agentic turn before it is prefilled again (~1,050 tok/s at 190k on fiona;
        # eklow DECISIONS 2026-11-08). A request may send its own preserve_thinking.
        preserveThinking = true;
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
        # slot gives its pages back and re-prefills later): beside the draft and the two image encoders each layer kept its
        # 91 busiest of 256 experts on the card instead of 48, decode +22% at 8k; with the checker and reranker loaded too
        # it keeps 67 (eklow DECISIONS 2026-11-11). The rest run on the CPU or stream in for prefill.
        contextSize = 262144;
        slots = 2;
        kvPool = 262144;
        kvInt8 = true;
        snapshotMiB = 4096;
        prefillGroup = 8;
        prefillGroupBusy = 4096;
      };

      # son-of-anton's end-of-turn checker for fiona's chats (its [checker]): laya's System One over vega's Qwen3.5-0.8B
      # reader, with the heads fitted on fiona's replay. eklow copies the policy into the unit's runtime folder at start
      # (systemd refuses a credential over 1 MiB; heads.npz is 6.4 MB).
      checker = {
        reader = eklowPkgs.vega-reader;
        policyFiles = {
          heads = config.age.secrets.eklow-checker-heads.path;
          calibration = config.age.secrets.eklow-checker-calibration.path;
          manifest = config.age.secrets.eklow-checker-manifest.path;
        };
      };
      reranker.model = eklowPkgs.qwen3-reranker;
    };

    # Fitted on private chats, so kept encrypted (secrets/agenix-rules.nix).
    age.secrets =
      lib.genAttrs
        [
          "eklow-checker-heads"
          "eklow-checker-calibration"
          "eklow-checker-manifest"
        ]
        (name: {
          file = ../../../secrets + "/${name}.age";
          mode = "0400";
        });

    systemOptions.firewall.allowFrom =
      let
        eklow = config.services.eklow;
      in
      lib.mkIf cfg.lanExpose (
        lib.genAttrs (map toString (
          lib.mapAttrsToList (_: inst: inst.port) eklow.instances
          ++ lib.optional (eklow.embedModel != null) eklow.embedPort
          ++ lib.optional (eklow.checker.reader != null) eklow.checker.port
          ++ lib.optional (eklow.reranker.model != null) eklow.reranker.port
        )) (_: config.systemOptions.llmServerClients)
      );
  };
}
