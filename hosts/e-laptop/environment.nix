{ config, pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  services.scx.enable = true;

  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    splashImage = null; # Disable splash image for text mode
    font = null; # Force console mode
    extraConfig = ''
      GRUB_TERMINAL_OUTPUT="console"
      GRUB_GFXMODE=1920x1080x32
      GRUB_GFXPAYLOAD_LINUX=keep
    '';
  };

  boot.initrd.luks.devices."luks-ae8141ce-edf4-4fea-b6b0-d8b4840de6c5".device =
    "/dev/disk/by-uuid/ae8141ce-edf4-4fea-b6b0-d8b4840de6c5";
  # Setup keyfile
  boot.initrd.secrets = { "/boot/crypto_keyfile.bin" = null; };

  boot.loader.grub.enableCryptodisk = true;

  boot.initrd.luks.devices."luks-5583f8f8-c4b2-4a11-9cce-5db033529ba6".keyFile =
    "/boot/crypto_keyfile.bin";
  boot.initrd.luks.devices."luks-ae8141ce-edf4-4fea-b6b0-d8b4840de6c5".keyFile =
    "/boot/crypto_keyfile.bin";

  services.logrotate.checkConfig = false;

  boot.loader.grub.configurationLimit = 5;
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "video=1920x1080"
    "resume=/dev/disk/by-uuid/b71761c0-68fa-41ca-9921-fcc6eb207eff"
  ];
  boot.resumeDevice = "/dev/disk/by-uuid/b71761c0-68fa-41ca-9921-fcc6eb207eff";
}
