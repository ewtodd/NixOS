{
  config,
  lib,
  ...
}:
{
  # RAG API powers LibreChat's "File Search" capability: uploaded documents are
  # chunked, embedded, and stored in pgvector, then retrieved by similarity at
  # query time. There is no nixpkgs package for danny-avila/rag_api, so we run
  # the upstream image (the "lite" variant, which uses a remote OpenAI-compatible
  # embeddings endpoint rather than bundling torch) alongside a pgvector Postgres,
  # both as podman containers. Embeddings go through the LiteLLM proxy to the
  # bge-m3 llama-server (see services.litellmProxy + llamaSwap).
  config = lib.mkIf config.systemOptions.services.ragApi.enable {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    virtualisation.oci-containers.containers = {
      # pgvector-backed Postgres store. Only rag-api talks to it, over the host
      # loopback published port; nothing is exposed to the LAN.
      rag-vectordb = {
        image = "pgvector/pgvector:pg16";
        ports = [ "127.0.0.1:5432:5432" ];
        environment = {
          POSTGRES_DB = "rag_api";
          POSTGRES_USER = "rag_api";
        };
        # POSTGRES_PASSWORD is supplied by the secret env file.
        environmentFiles = [ config.age.secrets.rag-api-env.path ];
        volumes = [ "rag-pgdata:/var/lib/postgresql/data" ];
      };

      rag-api = {
        image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest";
        dependsOn = [ "rag-vectordb" ];
        # Host networking lets it reach the vectordb (127.0.0.1:5432) and the
        # LiteLLM proxy (127.0.0.1:4000), and bind its own API on loopback for
        # LibreChat. Nothing is opened in the firewall.
        extraOptions = [ "--network=host" ];
        environment = {
          RAG_HOST = "127.0.0.1";
          RAG_PORT = "8000";

          # pgvector store (matches rag-vectordb above).
          VECTOR_DB_TYPE = "pgvector";
          POSTGRES_DB = "rag_api";
          POSTGRES_USER = "rag_api";
          DB_HOST = "127.0.0.1";
          DB_PORT = "5432";
          COLLECTION_NAME = "librechat";
          CHUNK_SIZE = "1500";
          CHUNK_OVERLAP = "100";

          # Embeddings via LiteLLM (OpenAI-compatible) -> bge-m3 behind llama-swap.
          # bge-m3 is not an OpenAI model, so disable the tiktoken ctx-length
          # check: it would otherwise pre-tokenize inputs into token-id arrays the
          # llama.cpp tokenizer can't interpret, and assume OpenAI dimensions.
          EMBEDDINGS_PROVIDER = "openai";
          EMBEDDINGS_MODEL = "bge-m3";
          RAG_OPENAI_BASEURL = "http://127.0.0.1:4000/v1";
          RAG_CHECK_EMBEDDING_CTX_LENGTH = "False";
        };
        # Secret env file provides POSTGRES_PASSWORD, RAG_OPENAI_API_KEY (a valid
        # LiteLLM key -- the env var MUST be named RAG_OPENAI_API_KEY, not
        # LITELLM_API_KEY) and JWT_SECRET (must equal LibreChat's JWT_SECRET so
        # rag_api can verify the user tokens LibreChat forwards).
        environmentFiles = [ config.age.secrets.rag-api-env.path ];
      };
    };

    # oci-containers reads the env file at container *create* time, and the
    # generated unit doesn't reference the secret's contents -- so editing
    # rag-api-env.age alone leaves the units byte-identical and activation never
    # restarts them (stale env). Triggering on the encrypted file's store path
    # (its hash changes with the contents) forces a recreate on the next deploy.
    systemd.services.podman-rag-api.restartTriggers = [ config.age.secrets.rag-api-env.file ];
    systemd.services.podman-rag-vectordb.restartTriggers = [ config.age.secrets.rag-api-env.file ];
  };
}
