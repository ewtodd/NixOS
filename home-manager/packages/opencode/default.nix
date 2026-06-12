{
  lib,
  osConfig ? null,
  ...
}:
let
  # Only e-devices reach the LiteLLM proxy + carry the master-key secret.
  # (Same osConfig gate used in ../shell/default.nix.)
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable else false;
in
{
  programs.opencode = lib.mkIf isEOwner {
    enable = true;

    # Follow the terminal's palette (your base16 scheme) instead of opencode's
    # own theme. The "system" theme derives its grayscale from the terminal
    # background and uses the standard ANSI colors. Written to tui.json.
    tui.theme = "system";

    # Global instructions, written to ~/.config/opencode/AGENTS.md and combined
    # with opencode's built-in prompt. Encodes the ROOT/C++ house style and
    # counters the built-in "be concise" directive for substantive changes.
    context = ''
      # House rules (mandatory)

      ## C++ / ROOT
      - In C++ that uses ROOT, use ROOT data types, and pick the *correct* one for
        the actual need rather than defaulting blindly: `Int_t` for ordinary ints,
        `Long64_t` for entry counts / large or 64-bit values, `Double_t` for
        floating point, `TString` for string convenience, and so on. Match the
        width and signedness the code actually requires.
      - In C++ generally, do not use modern C++ features: no `auto`, no smart
        pointers, no range-based (`for (x : c)`) iteration. Use explicit types and
        classic indexed/iterator loops.

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
        # These must mirror LiteLLM's model_list — opencode shows what's declared
        # here, it does not auto-discover from the endpoint.
        models = {
          auto = {
            name = "auto (content-routed)";
          };
          # the four tiers `auto` routes among (also selectable directly)
          fast-coder = {
            name = "fast-coder (e-desktop 14B)";
          };
          smart-coder = {
            name = "smart-coder (son-of-anton 80B-A3B)";
          };
          ultra-fast = {
            name = "ultra-fast (son-of-anton 30B-A3B)";
          };
          big-moe = {
            name = "big-moe (son-of-anton gpt-oss-120b)";
          };
          # name-only extras (never auto-routed)
          "qwen3.5-122b" = {
            name = "qwen3.5-122b (orchestrator alt)";
          };
          minimax = {
            name = "minimax (~230B experiment)";
          };
        };
      };
      model = "litellm/auto";

      # MCP servers (declarative -> opencode.json `mcp`). The nixos MCP gives
      # opencode live nixpkgs / NixOS-option / flake lookups. `nix run` builds
      # and caches it on first use. Pin a rev (github:utensils/mcp-nixos/<rev>)
      # if you want to avoid the per-launch flake update check.
      mcp.nixos = {
        type = "local";
        command = [
          "nix"
          "run"
          "github:utensils/mcp-nixos"
        ];
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
