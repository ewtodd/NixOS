let
  ethan-desktop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G";
  ethan-desktop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH";
  ethan-laptop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi";
  ethan-laptop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA";
  server-nu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwq6hEiSfrNBtsyxxvq0fUuxBV0kGRjnbHkcXL5XLmf root@server-nu";
  server-mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgHFqHi44REF+1/ikdJpoOuSbeSZ5DH6KAWYuXMP1rk root@server-mu";
  server-anton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfWKNZTYdp80kKGSoTdI/tc1CNLsZT07I/YtBGC5bjN root@anton";
  server-son-of-anton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICY75cWf+2GLiTlKSouy2l5bkeSm7t2PM3f+rSYqCXrl root@son-of-anton";
  personal = [
    ethan-desktop-ework
    ethan-desktop-eplay
    ethan-laptop-ework
    ethan-laptop-eplay
  ];
in
{
  "onyx-ssh-config.age".publicKeys = personal;
  "namecheap-ddns.age".publicKeys = personal ++ [ server-nu ];
  "e-desktop-luks-passphrase.age".publicKeys = personal ++ [ server-mu ];
  "bastion-initrd-unlock-key.age".publicKeys = personal ++ [ server-mu ];
  "nextcloud-admin-password.age".publicKeys = personal ++ [ server-mu ];
  "ntfy-publish-token.age".publicKeys = personal ++ [
    server-mu
    server-nu
    server-anton
    server-son-of-anton
  ];
  "grafana-admin-password.age".publicKeys = personal ++ [ server-nu ];
  "grafana-secret-key.age".publicKeys = personal ++ [ server-nu ];
  # son-of-anton runs the LiteLLM proxy; personal so e-devices can read it for opencode.
  "litellm-master-key.age".publicKeys = personal ++ [ server-son-of-anton ];
  # son-of-anton: SearXNG secret_key (read by the searx service as $SEARX_SECRET_KEY).
  "searxng-secret-key.age".publicKeys = personal ++ [ server-son-of-anton ];
  # son-of-anton: LibreChat env (CREDS_KEY/IV, JWT secrets, LITELLM_API_KEY).
  "librechat-env.age".publicKeys = personal ++ [ server-son-of-anton ];
  # son-of-anton: Meilisearch master key (message search). Raw key, no KEY= prefix.
  "meilisearch-api-key.age".publicKeys = personal ++ [ server-son-of-anton ];
  # son-of-anton: RAG API env (file search). Shared by the rag-api + pgvector
  # containers; KEY=value lines: POSTGRES_PASSWORD, RAG_OPENAI_API_KEY (a LiteLLM
  # key), JWT_SECRET (must match LibreChat's JWT_SECRET).
  "rag-api-env.age".publicKeys = personal ++ [ server-son-of-anton ];
}
