{ inputs, lib, ... }: {
  imports = [ "${inputs.nix-mineral}/nix-mineral.nix" ];
  lib.nm-overrides = {
    compatibility = {
      no-lockdown.enable = true;
      busmaster-bit.enable = true;
    };
    desktop = {
      allow-multilib.enable = true;
      allow-unprivelged-userns.enable = true;
      home-exec.enable = true;
      tmp-exec.enable = true;
      var-lib-exec.enable = true;
      nix-allow-all-users.enable = true;
      usbguard-disable.enable = true;
    };
    performance = {
      allow-smt.enable = true;
      no-pti.enable = true;
    };
    security = {
      tcp-timestamp-disable.enable = true;
      disable-intelme-kmodules.enable = true;
    };
    software-choice = { secure-chrony.enable = true; };
  };
}
