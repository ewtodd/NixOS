{ pkgs, config, ... }: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = false;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format "%c" --user-menu --greeting "Access is restricted to authorized personnel only. NO DOGS!" --cmd sway'';
        user = "greeter";
      };
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
  };
}
