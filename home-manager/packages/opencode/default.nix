{
  lib,
  osConfig ? null,
  ...
}:
let
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;
in
{
  programs.opencode = lib.mkIf isEOwner {
    enable = true;
    tui.theme = "system";
    context = ''
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

    settings = {
      provider.litellm = {
        npm = "@ai-sdk/openai-compatible";
        name = "LiteLLM";
        options = {
          baseURL = "https://llm.ethanwtodd.com/v1";
          apiKey = "{env:LITELLM_MASTER_KEY}";
        };
        models = {
          auto = {
            name = "auto";
          };
          smart-coder = {
            name = "son-of-anton qwen3-coder-next-80B-A3B";
          };
          ultra-fast = {
            name = "son-of-anton qwen3-30B-A3B";
          };
          big-moe = {
            name = "son-of-anton qwen3.5-122b";
          };
          "gpt-oss-120b" = {
            name = "son-of-anton gpt-oss-120b";
          };
        };
      };
      permission = {
        edit = "ask";
        bash = {
          "*" = "ask";
          "git status*" = "allow";
          "git diff*" = "allow";
          "git log*" = "allow";
          "grep *" = "allow";
          "rg *" = "allow";
          "ls *" = "allow";
          "ls -la *" = "allow";
        };
      };
      model = "litellm/auto";

      # fetch + SearXNG web_search + nixos lookups, served by the LiteLLM MCP
      # gateway on son-of-anton (the same tools LibreChat gets) — nixos used to
      # be a local `nix run` here but is now centralized on the gateway. Auth
      # via the master key.
      mcp.litellm = {
        type = "remote";
        # Trailing slash avoids LiteLLM's /mcp -> /mcp/ redirect; Bearer auth is
        # what LiteLLM's MCP endpoint requires (not x-litellm-api-key).
        url = "https://llm.ethanwtodd.com/mcp/";
        headers.Authorization = "Bearer {env:LITELLM_MASTER_KEY}";
        enabled = true;
      };
    };
  };

  programs.bash.initExtra = lib.mkIf isEOwner ''
    if [ -r /run/agenix/litellm-master-key ]; then
      set -a; . /run/agenix/litellm-master-key; set +a
    fi
  '';
}
