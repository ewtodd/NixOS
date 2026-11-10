{
  config,
  lib,
  ...
}:
let
  cfg = config.systemOptions.firewall.allowFrom;
in
{
  options.systemOptions.firewall.allowFrom = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.listOf (lib.types.strMatching "[0-9]+(\\.[0-9]+){3}(/[0-9]+)?")
    );
    default = { };
    example = {
      "7583" = [ "10.0.0.4" ];
    };
    description = ''
      TCP ports (as strings) opened only to the listed IPv4 sources, instead of
      to every host that can reach this one. Definitions from several modules
      concatenate.
    '';
  };

  # extraCommands runs after the allowed-port rules and before nixos-fw's final
  # refuse rule, so -A lands where an accept still counts.
  config.networking.firewall.extraCommands = lib.concatStrings (
    lib.mapAttrsToList (
      port: sources:
      lib.concatMapStrings (
        source: "iptables -w -A nixos-fw -p tcp -s ${source} --dport ${port} -j nixos-fw-accept\n"
      ) sources
    ) cfg
  );
}
