{
  lib,
  pkgs,
  inputs,
  osConfig ? null,
  ...
}:
let
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;

  qwenPkg = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qwen-code;

  baseUrl = "https://llm.ethanwtodd.com/v1";

  requestTimeoutMs = 1800000;

  # Auto-compaction in this qwen-code build has no configurable trigger %; the
  # old chatCompression.contextPercentageThreshold setting was removed. The
  # trigger is computed purely from the declared contextWindowSize as
  #   auto = max(0.70*window, window - compactReserve)
  # where compactReserve = SUMMARY_RESERVE(20000) + AUTOCOMPACT_BUFFER(13000).
  compactReserve = 33000;
  # Target: fire compaction at compactPercent of the model's REAL context. Since
  # qwen-code always subtracts compactReserve, we declare
  #   window = compactPercent*ctx + compactReserve
  # so the binding `window - compactReserve` branch lands at compactPercent*ctx.
  # This sits slightly ABOVE real ctx, which is safe: compaction fires well
  # before the real limit and the summarizer's input still fits — only the
  # in-flight response is squeezed. Trade-off at 90%: a reasoning model keeps
  # just ~10% of ctx (~13k tokens at 128k) for answer+thinking before truncation.
  compactPercent = 90;
  # qwen-code defaults to temperature=0 which overrides the proxy; use explicit
  # samplingParams (snake_case) instead. Unsloth-recommended for Qwen3.6 thinkers.
  sampling = {
    general = {
      temperature = 1.0;
      top_p = 0.95;
      top_k = 20;
      min_p = 0;
      presence_penalty = 1.5;
    };
    coding = {
      temperature = 0.6;
      top_p = 0.95;
      top_k = 20;
      min_p = 0;
      presence_penalty = 0;
    };
  };
  # samplingParams is null for models that should keep qwen-code's own defaults.
  mkModel =
    id: serverCtx: samplingParams:
    let
      # See compactPercent above: window chosen so `window - compactReserve`
      # lands the trigger at compactPercent of real ctx. Valid while serverCtx is
      # large enough that this beats the 0.70*window branch (serverCtx >~86k);
      # all chat models here are >=128k.
      ctxWindow = (serverCtx * compactPercent) / 100 + compactReserve;
    in
    {
      inherit id;
      name = id;
      envKey = "OPENAI_API_KEY";
      inherit baseUrl;
      generationConfig = {
        contextWindowSize = ctxWindow;
        timeout = requestTimeoutMs;
      }
      // lib.optionalAttrs (samplingParams != null) { inherit samplingParams; };
    };

  keyPlaceholder = "__LITELLM_MASTER_KEY__";

  settings = {
    modelProviders.openai = [
      (mkModel "Qwen3-Coder-Next (smart-coder)" 262144 null)
      (mkModel "Qwen3.6-35B-A3B (UD-Q8 coding)" 262144 sampling.coding)
      (mkModel "Qwen3.6-35B-A3B (UD-Q8 general)" 262144 sampling.general)
      # Dense reasoner on the R9700 eGPU; 128k server ctx (vs 262k for the MoEs).
      # serverCtx MUST match this model's llama-swap ctxSize, since the
      # compaction trigger is derived from it (see compactPercent above).
      (mkModel "Qwen3.6-27B (dense-reasoner)" 131072 sampling.general)
      (mkModel "Qwen3.5-122B-A10B (big-moe)" 262144 null)
    ];
    model.name = "Qwen3.6-27B (dense-reasoner)";
    security.auth.selectedType = "openai";

    mcpServers = lib.genAttrs [ "fetch" "searxng" "nixos" "arxiv" "context7" ] (server: {
      httpUrl = "https://llm.ethanwtodd.com/mcp/";
      headers = {
        Authorization = "Bearer ${keyPlaceholder}";
        "x-mcp-servers" = server;
      };
      trust = true;
    });

    mcp.allowed = [
      "fetch"
      "searxng"
      "nixos"
      "arxiv"
      "context7"
    ];
    mcp.excluded = [
      "fetch"
      "searxng"
      "nixos"
      "arxiv"
    ];

    # Over waypipe, WAYLAND_DISPLAY is set, so qwen-code's headless-SSH guard
    # treats this as a local graphical session and spawns `systemd-inhibit` to
    # block sleep while streaming/running tools. That triggers a polkit auth
    # prompt that flashes up and steals keyboard focus mid-activity (you can't
    # type or Shift-Tab). We don't need sleep inhibition here, so turn it off.
    general.preventSystemSleep = false;

    telemetry.enabled = false;
    model.generationConfig.timeout = requestTimeoutMs;
    ui.customWittyPhrases = [ "Let son-of-anton cook..." ];
    ui.autoModeAcknowledged = true;
  };

  settingsTemplate = (pkgs.formats.json { }).generate "qwen-settings.json" settings;
  secretPath = osConfig.age.secrets.litellm-master-key.path;

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
    export OPENAI_MODEL="''${OPENAI_MODEL:-Qwen3.6-27B (dense-reasoner)}"
    exec ${qwenPkg}/bin/qwen "$@"
  '';
in
{
  home.packages = lib.mkIf isEOwner [ qwen ];

  home.file.".qwen/QWEN.md" = lib.mkIf isEOwner {
    text = ''
      # Mandatory Rules

      ## In all languages
      - Prefer slightly verbose, self-explanatory code over terse code that needs
        comments to be understood.
      - Keep comments to only what explains something non-obvious.
      - Never embed a literal `\n` inside a string or print argument. A line break
        is always its own explicit statement. In C++/ROOT, use
        `std::cout << ... << std::endl;`. In Python, split output into separate
        `print()` calls, and use a bare `print()` for a blank line rather than
        appending `\n`.

      ## Nix
      - Always use flakes and flake-based commands (`nix run`, `nix shell`, etc.).
        Never use the old `nix-shell` approach.
      - If you are confused, stop and ask for help. This is especially critical in
        Nix.
      - Follow the existing style of the surrounding modules.

      ## C++ / ROOT
      - Use ROOT data types, and pick the *correct* one for the actual need rather
        than defaulting blindly: `Int_t` for ordinary ints, `Long64_t` for entry
        counts and large/64-bit values, `Double_t` for floating point, `TString`
        for string convenience, and so on. Match the width and signedness the code
        actually requires.
      - Do not use modern C++ features: no `auto`, no smart pointers, no
        range-based (`for (x : c)`) iteration. Use explicit types and classic
        indexed/iterator loops.
      - In performance-critical code, always gate logging behind a compile- or
        run-time toggle so it can be disabled. The `std::endl` flush is therefore
        never a concern on hot paths.

      ## Python
      - In Python that uses ROOT, never use matplotlib. Look at nearby files for the
        established plotting approach, or ask which is preferred.

      ## Explanations
      - For non-trivial changes, explain thoroughly what changed and why. Do not
      over-summarize or truncate the reasoning. Trivial edits can stay terse. 
    '';
  };
}
