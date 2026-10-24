{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# maitred (github.com/ewtodd/maitred, ~/Software/maitred): the house's AI front on :4002, keeping Bifrost's
# model ids and MCP tool names. /v1 lists every model with its context
# window, reasoning efforts and live status, and answers a request for a model whose son-of-anton mode is not
# loaded with what to use instead; /mcp aggregates the stdio MCP servers below, per key. The service itself is
# maitred's own NixOS module; this writes its settings.
let
  cfg = config.systemOptions.services.maitred;

  sonOfAnton = "10.0.0.5";
  fiona = "10.0.0.6";

  arxiv-mcp-server = pkgs.callPackage ./arxiv-mcp-server.nix {
    src = inputs.arxiv-mcp-server-src;
  };

  # son-of-anton's MCP grant: server -> allowed (unprefixed) tool names. Every granted schema rides every
  # inference request, so it is kept narrow. fetch and searxng are left out: son-of-anton's own
  # web_search/web_extract already front the same SearXNG. arxiv keeps its reading/search tools; the
  # watch/alert/export/reindex surface is rarely worth its schema.
  soaMcpTools = {
    nixos = [ "*" ];
    context7 = [ "*" ];
    arxiv = [
      "search_papers"
      "semantic_search"
      "search_paper_text" # physics.mcp.roles.manager
      "get_abstract"
      "get_paper_outline"
      "read_paper"
      "read_paper_section"
      "download_paper"
    ];
  };

  settings = {
    listen = "0.0.0.0:${toString cfg.port}";
    switch_hint = "ask the admin to switch son-of-anton to {mode} (llm-mode)";
    # "auto" leaves the model to maitred: the strongest tiered model below that is serving, fits the
    # conversation and has a free slot, keeping a conversation on the model that has it cached. Not a
    # fallback: a request naming a model still gets that model or the not-loaded error. Cron asks for it, so
    # its jobs run on whichever mode son-of-anton has up. Each decision is a JSON line in the log.
    router.decision_log = "/var/lib/maitred/routes.jsonl";
    # slots: how many requests each server runs at once (son-of-anton's maxNumSeqs; gufo's sessions).
    upstreams = {
      # A cold 1M-token prefill takes ~20 min before the first token.
      unholy = {
        base_url = "http://${sonOfAnton}:8200/v1";
        timeout_secs = 3600;
        idle_timeout_secs = 3600;
        slots = 8;
      };
      radiance = {
        base_url = "http://${sonOfAnton}:8100/v1";
        timeout_secs = 1800;
        slots = 8;
      };
      gufo = {
        base_url = "http://${sonOfAnton}:8050/v1";
        timeout_secs = 1800;
        slots = 2;
      };
      # llama.cpp on fiona: the title model, Gemma 4 and the embedding server.
      llama = {
        base_url = "http://${fiona}:8080/v1";
        timeout_secs = 1800;
      };
      gemma = {
        base_url = "http://${fiona}:8081/v1";
        timeout_secs = 1800;
        slots = 2;
      };
      embed = {
        base_url = "http://${fiona}:8082/v1";
        timeout_secs = 120;
      };
      deepseek = {
        base_url = "https://api.deepseek.com/v1";
        api_key_env = "DEEPSEEK_API_KEY";
        timeout_secs = 1800;
      };
    };
    modes = [
      {
        name = "ds4";
        label = "DeepSeek-V4-Flash";
        host = "son-of-anton";
        upstreams = [ "unholy" ];
      }
      {
        name = "qwen";
        label = "the Qwen models";
        host = "son-of-anton";
        upstreams = [
          "radiance"
          "gufo"
        ];
      }
    ];
    # reasoning_efforts: what each server takes (unholy: none/low/high/max; Radiance, as its /v1/models lists:
    # none/minimal/low/medium/xhigh, answering high and max with a 400; gufo takes everything, but its
    # template has none/low/medium/xhigh; Gemma 4's template only turns thinking on or off). The Qwen pair alias
    # high to xhigh, their default, so "high" means each model's normal thinking whichever one "auto" lands on
    # (clamping would give them medium). tier: DeepSeek-V4-Flash, then Qwen3.8-27B, then Flash-Next, which
    # "auto" takes when Radiance is full or down, then Gemma 4 on fiona, which is up when son-of-anton is not.
    models = [
      {
        id = "unholy/dsv4-flash";
        upstream = "unholy";
        upstream_model = "dsv4-flash";
        display_name = "DeepSeek-V4-Flash";
        context_length = 524288;
        reasoning_efforts = [
          "none"
          "low"
          "high"
          "max"
        ];
        default_reasoning_effort = "high";
        effort_aliases = {
          minimal = "low";
          medium = "high";
          xhigh = "max";
        };
        tier = 3;
      }
      {
        id = "radiance/qwen3.8-27b";
        upstream = "radiance";
        upstream_model = "qwen3.8-27b";
        display_name = "Qwen3.8-27B";
        context_length = 352256;
        reasoning_efforts = [
          "none"
          "minimal"
          "low"
          "medium"
          "xhigh"
        ];
        default_reasoning_effort = "xhigh";
        effort_aliases.high = "xhigh";
        tier = 2;
      }
      {
        id = "gufo/qwen3.8-flash-next";
        upstream = "gufo";
        upstream_model = "qwen3.8-flash-next";
        display_name = "Qwen3.8-Flash-Next";
        context_length = 262144;
        reasoning_efforts = [
          "none"
          "low"
          "medium"
          "xhigh"
        ];
        default_reasoning_effort = "xhigh";
        effort_aliases.high = "xhigh";
        tier = 1;
      }
      {
        id = "llama/gemma-4-26b-a4b";
        upstream = "gemma";
        upstream_model = "gemma-4-26b-a4b";
        display_name = "Gemma 4 26B A4B";
        context_length = 32768;
        reasoning_efforts = [
          "none"
          "high"
        ];
        default_reasoning_effort = "high";
        tier = 0;
      }
      {
        id = "llama/little-titles";
        upstream = "llama";
        upstream_model = "little-titles";
        display_name = "Little-Titles";
        context_length = 4096;
        # Title generation only; every consumer names it outright. Kept out of the /v1/models
        # listing so the agent pickers show chat models.
        hidden = true;
      }
      # The same model forced to answer {"title": ...}: Open WebUI parses its titles as JSON and falls back to the
      # user's first message when the reply is plain text, which is what Little-Titles answers with on Open
      # WebUI's prompt. llama.cpp turns the schema into a grammar. (LiteLLM's little-titles-json route did this.)
      # Hidden like its sibling: Open WebUI validates TASK_MODEL_EXTERNAL against the listing, so its titles
      # fall back to the chat model (plain text -> the user's first message) until it is unhidden.
      {
        id = "llama/little-titles-json";
        upstream = "llama";
        upstream_model = "little-titles";
        display_name = "Little-Titles (JSON)";
        context_length = 4096;
        hidden = true;
        request_overrides.response_format = {
          type = "json_schema";
          json_schema = {
            name = "title";
            strict = true;
            schema = {
              type = "object";
              properties.title.type = "string";
              required = [ "title" ];
              additionalProperties = false;
            };
          };
        };
      }
      {
        id = "embed/embeddinggemma-2";
        upstream = "embed";
        upstream_model = "embeddinggemma-2";
        display_name = "EmbeddingGemma 2";
        context_length = 8192;
        # Embeddings only; every consumer names it outright.
        hidden = true;
      }
      {
        id = "deepseek/deepseek-flash";
        upstream = "deepseek";
        upstream_model = "deepseek-flash";
        display_name = "DeepSeek API (Flash)";
        context_length = 1048576;
        reasoning_efforts = [
          "low"
          "high"
          "max"
        ];
        default_reasoning_effort = "max";
      }
    ];
    keys = [
      {
        name = "opencode";
        env = "MAITRED_KEY_OPENCODE";
        # opencode's web search (its nixos MCP runs locally).
        mcp.searxng = [ "*" ];
      }
      {
        name = "open-webui";
        env = "MAITRED_KEY_OPENWEBUI";
      }
      {
        name = "son-of-anton";
        env = "MAITRED_KEY_SOA";
        mcp = soaMcpTools;
      }
      {
        # The Knoll bench pipeline feeds these models private session data, so the list is LAN-served
        # models only: deepseek/* is DeepSeek's hosted API, and auto is left out so every call pins its model.
        name = "knoll";
        env = "MAITRED_KEY_KNOLL";
        models = [
          "unholy/dsv4-flash"
          "radiance/qwen3.8-27b"
          "gufo/qwen3.8-flash-next"
          "embed/embeddinggemma-2"
        ];
      }
    ];
    # The stdio MCP servers behind /mcp; a tool t of server s is offered as s-t.
    mcp = {
      fetch.command = lib.getExe pkgs.mcp-server-fetch;
      searxng = {
        command = lib.getExe pkgs.mcp-searxng;
        env.SEARXNG_URL = "http://127.0.0.1:8888";
      };
      nixos.command = lib.getExe pkgs.mcp-nixos;
      arxiv = {
        command = lib.getExe arxiv-mcp-server;
        args = [
          "--storage-path"
          "/var/lib/maitred/arxiv-papers"
        ];
      };
      context7.command = lib.getExe pkgs.context7-mcp;
    };
  };

in
{
  imports = [ inputs.maitred.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.maitred = {
      enable = true;
      inherit settings;
      inherit (cfg) openFirewall;
      inherit (cfg) environmentFiles;
    };
  };
}
