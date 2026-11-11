{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow) on the Arc A770M: one engine serving fiona's chat model, NVIDIA's
# Nemotron-3.5-Bolt-E4B (`bolt`, eklow-bolt.service, an `llm-mode` of its name in modules/services/llm-mode), on the
# port maitred's eklow upstream names (8081), and beside it EmbeddingGemma 2 (embed's port, 8082), son-of-anton's
# end-of-turn checker (8084) and Qwen3-Reranker (8085). Sage-A1.5 (Qwen3.6-35B-A3B) was fiona's model until
# 2026-11-11; eklow dropped the Qwen chat path then. The service is eklow's own NixOS module; this sets the models,
# the house's window and exposure.
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
      # (7.2.0, 2026-11-02) it ran 6-9% slower and found 0.8 GiB less card memory free after loading.
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
