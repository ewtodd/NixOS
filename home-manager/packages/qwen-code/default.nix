{
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;

  baseUrl = "https://llm.ethanwtodd.com/v1";

  # One OpenAI-compatible provider entry per LiteLLM model_name. `id`/`name` are
  # the model id sent upstream (must match LiteLLM's model_list); `envKey` names
  # the env var holding the key. ctx mirrors the corresponding llama-swap
  # --ctx-size so qwen's context bookkeeping agrees with the server. These drive
  # the /model picker; the OPENAI_* env vars in the wrapper select the default
  # and satisfy auth. Keep in sync with the litellm-proxy model_list + the
  # LibreChat picker.
  mkModel = id: ctx: {
    inherit id;
    name = id;
    envKey = "OPENAI_API_KEY";
    inherit baseUrl;
    generationConfig.contextWindowSize = ctx;
  };

  # Substituted with the real master key when the wrapper renders settings.json.
  keyPlaceholder = "__LITELLM_MASTER_KEY__";

  settings = {
    modelProviders.openai = [
      (mkModel "Qwen3-Coder-Next (smart-coder)" 131072)
      (mkModel "Qwen3.6-35B-A3B (default)" 131072)
      (mkModel "Qwen3-30B-A3B-Instruct-2507 (ultra-fast)" 65536)
      (mkModel "Qwen3.5-122B-A10B (big-moe)" 131072)
      (mkModel "gpt-oss-120b" 131072)
      (mkModel "NVIDIA-Nemotron-3-Super-120B-A12B" 131072)
      (mkModel "Mistral-Small-4-119B (vision)" 65536)
      (mkModel "Mistral-Medium-3.5-128B (vision)" 65536)
      (mkModel "Step-3.7-Flash (vision)" 65536)
      (mkModel "MiniMax-M2.7 (uncensored)" 131072)
    ];
    # Coding orchestrator default: the model actually trained for the agentic
    # tool-call loop (qwen-code is a gemini-cli fork that lives or dies on it).
    model.name = "Qwen3-Coder-Next (smart-coder)";
    security.auth.selectedType = "openai";

    # One entry per LiteLLM MCP server (fetch + SearXNG web_search + nixos/arxiv/
    # context7) rather than a single aggregated gateway, so the agent isn't handed
    # every tool at once (fewer tools = fewer tool-call loops). All hit the same
    # endpoint on son-of-anton; the `x-mcp-servers` header scopes each connection
    # to one server. httpUrl = streamable-HTTP; trailing slash avoids the /mcp ->
    # /mcp/ redirect; Bearer auth is what LiteLLM's MCP endpoint requires.
    mcpServers =
      lib.genAttrs
        [
          "fetch"
          "searxng"
          "nixos"
          "arxiv"
          "context7"
        ]
        (server: {
          httpUrl = "https://llm.ethanwtodd.com/mcp/";
          headers = {
            Authorization = "Bearer ${keyPlaceholder}";
            "x-mcp-servers" = server;
          };
          trust = true;
        });
  };

  settingsTemplate = (pkgs.formats.json { }).generate "qwen-settings.json" settings;

  # agenix-decrypted env file (LITELLM_MASTER_KEY=...), declared under the same
  # owner.e.enable guard as this module, so it's defined wherever the wrapper is
  # installed. Reference the option's path rather than hardcoding /run/agenix.
  secretPath = osConfig.age.secrets.litellm-master-key.path;

  # qwen-code 0.16.0 ignores the settings.json modelProviders/auth path and
  # drops to its onboarding "connect a provider" picker. The OPENAI_* env vars
  # are the mechanism it reliably honors -- set them and it auto-selects the
  # openai auth type and skips onboarding. We wrap `qwen` so those vars are
  # scoped to qwen alone (no redirecting other OpenAI SDK/tooling in the shell),
  # and so the wrapper is fully self-contained: it sources the key, renders
  # ~/.qwen/settings.json with the MCP Bearer token baked in (kept at mode 600,
  # out of the world-readable store), then execs the real qwen.
  qwen = pkgs.writeShellScriptBin "qwen" ''
    if [ -r ${secretPath} ]; then
      set -a; . ${secretPath}; set +a
    fi
    if [ -z "''${LITELLM_MASTER_KEY:-}" ]; then
      echo "qwen: LITELLM_MASTER_KEY unavailable (${secretPath} missing?)" >&2
      exit 1
    fi
    mkdir -p "$HOME/.qwen"
    ( umask 077
      sed "s|${keyPlaceholder}|$LITELLM_MASTER_KEY|g" ${settingsTemplate} \
        > "$HOME/.qwen/settings.json" )
    export OPENAI_API_KEY="$LITELLM_MASTER_KEY"
    export OPENAI_BASE_URL="${baseUrl}"
    export OPENAI_MODEL="''${OPENAI_MODEL:-Qwen3-Coder-Next (smart-coder)}"
    exec ${lib.getExe pkgs.qwen-code} "$@"
  '';
in
{
  # Only the wrapper goes on PATH (it calls the real qwen-code by store path);
  # adding both would collide on bin/qwen.
  home.packages = lib.mkIf isEOwner [ qwen ];

  # Global context/rules (qwen-code's default context file is QWEN.md). Ported
  # verbatim from the old opencode `context`.
  home.file.".qwen/QWEN.md" = lib.mkIf isEOwner {
    text = ''
      # Mandatory Rules

      ## C++ / ROOT
      - In C++ that uses ROOT, use ROOT data types, and pick the *correct* one for
      the actual need rather than defaulting blindly: `Int_t` for ordinary ints,
      `Long64_t` for entry counts / large or 64-bit values, `Double_t` for
      floating point, `TString` for string convenience, and so on. Match the
      width and signedness the code actually requires.
      - In C++ generally, do not use modern C++ features: no `auto`, no smart
      pointers, no range-based (`for (x : c)`) iteration. Use explicit types and
      classic indexed/iterator loops.

      ## Python
      - In Python that uses ROOT, never use matplotlib for plotting.
      Either look at nearby files for examples of how to properly plot,
      or ask the user what they prefer.

      ## Explanations
      - For non-trivial changes to the codebase, give thorough explanations of
      what changed and why. Do not over-summarize or truncate reasoning for
      these (trivial edits can still be terse).
    '';
  };
}
