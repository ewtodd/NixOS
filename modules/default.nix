# This file is kept for backwards compatibility
# The actual module structure is now in common/, nixos/, and darwin/
{ ... }:
{
  imports = [
    ./common
  ];
}
