{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    inkscape
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ];
}
