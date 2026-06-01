{
  pkgs,
  ...
}:
let
  lenovo-ish = pkgs.stdenvNoCC.mkDerivation {
    name = "lenovo-ish-firmware";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/firmware/intel/ish
      cp ${pkgs.linux-firmware}/lib/firmware/intel/ish/ish_lnlm_53c4ffad_cb391961.bin $out/lib/firmware/intel/ish/ish_lnlm.bin
    '';
  };
in
{

  boot.kernelPackages = pkgs.linuxPackages_xanmod_stable;
  hardware.firmware = [ lenovo-ish ];

  boot.initrd.systemd.enable = true;
  systemd.units."dev-tpm0.device".enable = false;
  systemd.services.systemd-tpm2-setup.enable = false;
  systemd.services.systemd-tpm2-setup-early.enable = false;

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };

  boot.loader.efi.canTouchEfiVariables = true;

  boot.resumeDevice = "/dev/disk/by-uuid/029a5a42-5427-4d8d-9106-dda86cfdc5a0";
}
