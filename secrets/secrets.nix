let
  ethan-desktop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G";
  ethan-desktop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH";
  ethan-laptop-ework = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5aPPhXY+RssvL9znCFwHjkmUdi4KQkNSnAgd+AQqqx";
  ethan-laptop-eplay = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQQfBHV/kgznCsuV6uUbEUW5bb5WKx3vvWhQAAOmlZJ";
  server-nu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKwq6hEiSfrNBtsyxxvq0fUuxBV0kGRjnbHkcXL5XLmf root@server-nu";
  server-mu = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgHFqHi44REF+1/ikdJpoOuSbeSZ5DH6KAWYuXMP1rk root@server-mu";

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
  ];
}
