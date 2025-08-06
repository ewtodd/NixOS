{ pkgs, inputs, system, ...}: {
  {
  virtualisation.docker.enable = true;

  # Make sure your user can use Docker without sudo
  users.users.v-work.extraGroups = [ "docker" ];
}
}

