{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ]
  ++ (with pkgs; [
    proton-pass
    gost
  ]);
}
