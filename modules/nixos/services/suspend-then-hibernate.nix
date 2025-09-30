{ ... }: {
  powerManagement.enable = true;
  services.logind.lidSwitch = "suspend-then-hibernate";
  services.logind.powerKey = "hibernate";
  services.logind.powerKeyLongPress = "poweroff";

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=1m
  '';
}
