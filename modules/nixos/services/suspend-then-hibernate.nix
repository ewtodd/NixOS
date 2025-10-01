{ ... }: {
  powerManagement.enable = true;

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=20m
  '';
}
