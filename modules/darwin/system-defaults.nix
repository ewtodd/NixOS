{ lib, ... }:
{
  config = {
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

    system.defaults.smb.NetBIOSName = lib.mkDefault "darwin-host";
  };
}
