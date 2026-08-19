let
  ethan-desktop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G";
  ethan-desktop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH";
  ethan-laptop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi";
  ethan-laptop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA";
  val-laptop-vwork = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhKUIc/JCW80ZOcEnL4mTFx35bp/AyRYVtJXpdamnDB";
  val-laptop-vplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILO1NgdbMcu5dL8bw6MGINcRLZFq1okTXepZsXuYYnlU";
  nu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwq6hEiSfrNBtsyxxvq0fUuxBV0kGRjnbHkcXL5XLmf root@nu";
  mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgHFqHi44REF+1/ikdJpoOuSbeSZ5DH6KAWYuXMP1rk root@mu";
  server-anton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfWKNZTYdp80kKGSoTdI/tc1CNLsZT07I/YtBGC5bjN root@anton";
  server-son-of-anton = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJNP13u10CY6dMNzWze+Hk+as+Esm35XGR4WGXMccgtH root@son-of-anton";
  server-oracle = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzfIzVGX+XNGWRrLfL78OeYqt8MB5Xii9EwimFAL0WZ root@oracle";
  server-e-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJPftrHYU/cCgJyXdpIX5FHNpjqfnHRLkytx65JV4uHO root@e-desktop";
  personal = [
    ethan-desktop-ework
    ethan-desktop-eplay
    ethan-laptop-ework
    ethan-laptop-eplay
  ];
  val = [
    val-laptop-vwork
    val-laptop-vplay
  ];
in
{
  "onyx-ssh-config.age".publicKeys = personal;
  "namecheap-ddns.age".publicKeys = personal ++ [ nu ];
  "e-desktop-luks-passphrase.age".publicKeys = personal ++ [ mu ];
  "bastion-initrd-unlock-key.age".publicKeys = personal ++ [ mu ];
  "nextcloud-admin-password.age".publicKeys = personal ++ [ mu ];
  "grafana-admin-password.age".publicKeys = personal ++ [ nu ];
  "grafana-secret-key.age".publicKeys = personal ++ [ nu ];
  "searxng-secret-key.age".publicKeys = personal ++ [
    server-son-of-anton
    server-oracle
  ];
  "librechat-env.age".publicKeys = personal ++ [
    server-son-of-anton
    server-oracle
  ];
  "meilisearch-api-key.age".publicKeys = personal ++ [
    server-son-of-anton
    server-oracle
  ];
  "litellm-master-key.age".publicKeys =
    personal ++ [ server-son-of-anton ] ++ val ++ [ server-oracle ];
  "litellm-deepseek-key.age".publicKeys = personal ++ [ server-oracle ];
  "temple-server-env.age".publicKeys = personal ++ [
    server-oracle
    server-e-desktop
  ];
  "signal-cli-env.age".publicKeys = personal ++ [ mu ];
  "proton-mail-bridge.age".publicKeys = personal;
}
