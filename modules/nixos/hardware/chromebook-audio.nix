{ config, pkgs, lib, ... }:

let
  cb-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs {
    wttsrc = pkgs.fetchurl {
      url =
        "https://github.com/WeirdTreeThing/chromebook-ucm-conf/archive/1328e46bfca6db2c609df9c68d37bb418e6fe279.tar.gz";
      hash = "sha256-eTP++vdS7cKtc8Mq4qCzzKtTRM/gsLme4PLkN0ZWveo=";
    };
    unpackPhase = ''
      runHook preUnpack
      tar xf "$src"
      tar xf "$wttsrc"
      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/alsa
      cp -r alsa-ucm*/{ucm,ucm2} $out/share/alsa
      cp -r chromebook-ucm*/common $out/share/alsa/ucm2
      cp -r chromebook-ucm*/adl/* $out/share/alsa/ucm2/conf.d
      runHook postInstall
    '';
  };
in {
  boot = {
    extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=3
    '';
  };
  environment = {
    systemPackages = [ pkgs.sof-firmware ];
    sessionVariables.ALSA_CONFIG_UCM2 = "${cb-ucm-conf}/share/alsa/ucm2";
  };
  system.replaceDependencies.replacements = [{
    original = pkgs.alsa-ucm-conf;
    replacement = cb-ucm-conf;
  }];

  services.pipewire.wireplumber.configPackages = [
    (pkgs.writeTextDir
      "share/wireplumber/main.lua.d/51-increase-headroom.lua" ''
        rule = {
          matches = {
            {
              { "node.name", "matches", "alsa_output.*" },
            },
          },
          apply_properties = {
            ["api.alsa.headroom"] = 4096,
          },
        }

        table.insert(alsa_monitor.rules,rule)
      '')
  ];
}
