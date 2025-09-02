{ config, pkgs, inputs, ... }: {
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.interception-tools = {
    enable = true;
    plugins = with pkgs.interception-tools-plugins; [
      caps2esc
      dual-function-keys
    ];
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
          EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };

  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;
  services.avahi.openFirewall = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.gnome.gnome-keyring.enable = true;
  security.polkit = { enable = true; };
  environment.systemPackages = with pkgs; [ polkit_gnome ];

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
  security.rtkit.enable = true;
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
