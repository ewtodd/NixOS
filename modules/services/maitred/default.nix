{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

# maitred (github.com/ewtodd/maitred, ~/Software/maitred): the house's AI front on :4002, in Bifrost's place
# with its virtual keys (bifrost-keys), model ids and MCP tool names. /v1 lists every model with its context
# window, reasoning efforts and live status, and answers a request for a model whose son-of-anton mode is not
# loaded with what to use instead; /mcp aggregates the stdio MCP servers below, per key. The service itself is
# maitred's own NixOS module; this writes its settings.
let
  cfg = config.systemOptions.services.maitred;

  sonOfAnton = "10.0.0.5";

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
    upstreams = {
      # A cold 1M-token prefill takes ~20 min before the first token.
      unholy = {
        base_url = "http://${sonOfAnton}:8200/v1";
        timeout_secs = 3600;
        idle_timeout_secs = 3600;
      };
      radiance = {
        base_url = "http://${sonOfAnton}:8100/v1";
        timeout_secs = 1800;
      };
      gufo = {
        base_url = "http://${sonOfAnton}:8050/v1";
        timeout_secs = 1800;
      };
      # llama.cpp (the title model) and the embedding server, on this host.
      llama = {
        base_url = "http://127.0.0.1:8080/v1";
        timeout_secs = 1800;
      };
      embed = {
        base_url = "http://127.0.0.1:8082/v1";
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
    # template has none/low/medium/xhigh).
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
      }
      {
        id = "llama/little-titles";
        upstream = "llama";
        upstream_model = "little-titles";
        display_name = "Little-Titles";
        context_length = 4096;
      }
      # The same model forced to answer {"title": ...}: Open WebUI parses its titles as JSON and falls back to the
      # user's first message when the reply is plain text, which is what Little-Titles answers with on Open
      # WebUI's prompt. llama.cpp turns the schema into a grammar. (LiteLLM's little-titles-json route did this.)
      {
        id = "llama/little-titles-json";
        upstream = "llama";
        upstream_model = "little-titles";
        display_name = "Little-Titles (JSON)";
        context_length = 4096;
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
        id = "embed/bge-m3";
        upstream = "embed";
        upstream_model = "bge-m3";
        display_name = "bge-m3";
        context_length = 8192;
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
    # The virtual keys from Bifrost's days, unchanged (bifrost-keys). The friend key gets the three
    # son-of-anton chat models (whichever mode is loaded) during ricky's hours; outside them the refusal says
    # when.
    keys = [
      {
        name = "opencode";
        env = "BIFROST_OPENCODE_VK";
        # opencode's web search (its nixos MCP runs locally).
        mcp.searxng = [ "*" ];
      }
      {
        name = "open-webui";
        env = "BIFROST_OPENWEBUI_VK";
      }
      {
        name = "son-of-anton";
        env = "BIFROST_SOA_VK";
        mcp = soaMcpTools;
      }
      {
        name = "friend";
        env = "BIFROST_FRIEND_VK";
        models = [
          "unholy/dsv4-flash"
          "radiance/qwen3.8-27b"
          "gufo/qwen3.8-flash-next"
        ];
        rate_limit = {
          requests = 30;
          per_secs = 60;
        };
        active_hours = {
          start = 20;
          end = 7;
          timezone = "America/Chicago";
          message = "The friend key is only active 20:00-07:00 America/Chicago (8pm-7am).";
        };
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
      # Virtual keys (bifrost-keys) and the DeepSeek key (bifrost-env; its other variables were Bifrost's).
      inherit (cfg) environmentFiles;
    };
  };
}
