{ inputs, ... }:
let
  remarkable = inputs.remarkable.packages."x86_64-linux".default;
in
{
  environment.systemPackages = [ remarkable ];
}
