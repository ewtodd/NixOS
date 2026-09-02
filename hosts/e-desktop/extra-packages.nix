{
  pkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = [
    inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena # fleet deploy (build host)
  ]
  ++ (with pkgs; [
    proton-pass
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
  ]);
}
