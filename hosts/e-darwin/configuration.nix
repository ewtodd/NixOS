{ lib, pkgs, ... }:
with lib;
{
  options = {
    systemOptions = {
      owner.e.enable = mkEnableOption "Whether this is an e-device. If it isn't then it must be a v-device!";
    };
  };
  config = {
    systemOptions = {
      owner.e.enable = true;
    };

    system.primaryUser = "e-host";
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
        extraFlags = [
          "--verbose"
        ];
      };
      brews = [
        "FelixKratz/formulae/borders"
        "j-x-z/tap/cocoa-way"
        "j-x-z/tap/waypipe-darwin"
      ];
      casks = [
        "hammerspoon"
        "orbstack"
        "amethyst"
        "karabiner-elements"
      ];
    };

    environment.systemPackages = with pkgs; [
      git
      gh
      nh
      wget
      tree
      nixfmt
      tree
      usbutils
      poppler-utils
      pciutils
      unzip
      zip
      imagemagick
      ghostscript
    ];

    networking.hostName = "e-darwin";
    networking.computerName = "e-darwin";
    system.defaults.smb.NetBIOSName = "e-darwin";
    nix.settings.experimental-features = "nix-command flakes";

    system.configurationRevision = null;
    system.stateVersion = 6;

    nixpkgs.hostPlatform = "aarch64-darwin";
    users.users.e-host = {
      name = "e-host";
      home = "/Users/e-host";
      shell = pkgs.zsh;
    };

    system.defaults.NSGlobalDomain = {
      AppleSpacesSwitchOnActivate = false;
      InitialKeyRepeat = 14;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 1;
    };

    system.defaults.dock = {
      autohide = true;
      mru-spaces = false;
    };

  };
}
