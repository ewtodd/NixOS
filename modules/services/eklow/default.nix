{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# eklow (github.com/ewtodd/eklow, ~/Software/eklow) on the Arc A770M: one engine serving fiona's chat model, Thinking
# Machines' Inkling 2 Mini (`inkling`, eklow-inkling.service, an `llm-mode` of its name in modules/services/llm-mode), on
# the port maitred's eklow upstream names (8081), and beside it EmbeddingGemma 2 (embed's port, 8082), son-of-anton's
# end-of-turn checker (8084) and Qwen3-Reranker (8085). NVIDIA's Nemotron-3.5-Bolt-E4B was fiona's model from 2026-11-10
# until the owner stopped it on 2026-11-24; Sage-A1.5 (Qwen3.6-35B-A3B) before it, until 2026-11-11. The service is eklow's own NixOS module; this sets the models,
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

      instances.inkling = {
        # Unsloth's UD-Q4_K_M (eklow nix/models.nix), the file fiona's sandboxed replay scored 110 of 126 on llama.cpp
        # (Bolt: 16 of 48); through eklow 40 of 41 where llama.cpp passed 41 of 42 on the same moments (eklow DECISIONS
        # 2026-11-24, "Inkling M4"). 15.5 GiB: the experts the card has no room for run on fiona's CPU, chosen by the
        # routing profile the package ships. Decode ~10.5 tok/s, prefill ~365 tok/s; text only until eklow ports its vision.
        model = eklowPkgs.inkling-2-mini;
        alias = "inkling-2-mini";
        expertProfile = "${eklowPkgs.default}/share/eklow/inkling-2-mini-experts.json";
        port = 8081;
        slots = 2;
        contextSize = 65536;
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

      # Bolt's disk prefix cache (eklow DECISIONS 2026-11-22): Inkling keeps none (its sliding rings and convolution states
      # are rewound from checkpoints in host memory), and eklow-server refuses the flag for it. Bolt's pages stay in
      # /var/lib/private/eklow-bolt until deleted.
      prefixCache = {
        enable = false;
        keyFile = config.age.secrets.eklow-prefix-cache-key.path;
      };
    };

    # The checker's policy was fitted on private chats and the cache's pages are chats, so both are kept encrypted
    # (secrets/agenix-rules.nix).
    age.secrets =
      lib.genAttrs
        [
          "eklow-checker-heads"
          "eklow-checker-calibration"
          "eklow-checker-manifest"
          "eklow-prefix-cache-key"
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
