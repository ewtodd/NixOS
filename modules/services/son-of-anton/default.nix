{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.son-of-anton;

  # The account's CLI and its Signal service share one
  # ~/.son-of-anton/config.yaml — that shared home is what makes a Signal
  # conversation resumable from the terminal. So the per-surface model split
  # comes out of one file: `model.default` is what the CLI opens with,
  # `gateway.model` is what the service answers with.
  # Shared settings, then what this instance derives, then its own overrides.
  # Later wins at every level, so an instance can override one nested key
  # (router.modes, say) without restating the rest.
  settingsFor =
    inst:
    lib.foldl lib.recursiveUpdate cfg.settings [
      {
        terminal.cwd = inst.workingDirectory;
      }
      (lib.optionalAttrs (inst.model != "") {
        gateway.model = inst.model;
      })
      inst.settings
    ];
in
{
  imports = [ inputs.son-of-anton.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    # Secret-access group only. The instances run as their own accounts and do
    # not share a primary group; this exists so one agenix .env can be read by
    # all of them at 0440 rather than being copied per account.
    users.groups.son-of-anton = { };

    services.son-of-anton.instances = lib.mapAttrs (name: inst: {
      enable = true;
      inherit (inst)
        user
        createUser
        managedAccount
        son-of-antonHome
        workingDirectory
        protectedPaths
        ;
      group = "son-of-anton";

      # HOME for the unit. For a login account the module uses the account's
      # own home and ignores this; for a CREATED account it defaults stateDir
      # from the INSTANCE NAME, so an instance named `house` running as
      # `soa-house` would get HOME=/var/lib/son-of-anton-house while its state
      # lived under /var/lib/soa-house. Pin it to where the state actually is.
      stateDir = if inst.stateDir != "" then inst.stateDir else "/var/lib/son-of-anton-${name}";

      # Not addToSystemPackages: that sets environment.variables globally, so
      # ONE instance's home would leak into every account's shell — including
      # accounts whose own home is elsewhere. (That exact leak is why an e-play
      # shell was seen carrying SON_OF_ANTON_HOME=/home/e-work/.son-of-anton.)
      # The CLI is installed unconditionally below instead.
      addToSystemPackages = false;

      # Shared secrets first, then this instance's own. Order is the mechanism:
      # mkEnvScript cats them into .env in sequence and the dotenv reader takes
      # the LAST assignment, so an instance's file overrides a shared value.
      # That is how house widens SIGNAL_ALLOWED_USERS to two people without
      # authorizing the second one on work and play.
      environmentFiles = cfg.environmentFiles ++ inst.environmentFiles;
      environment = cfg.environment // {
        # DMs carry no group id, so they cannot be routed to one instance.
        # Left on, a single DM would produce one agent turn and one reply per
        # running service. Dropped at intake, before any session or tokens.
        SIGNAL_DM_MODE = "ignore";
      };
      settings = settingsFor inst;
      extraPackages = cfg.extraPackages ++ inst.extraPackages;
    }) cfg.instances;

    # One CLI for every account. No SON_OF_ANTON_HOME is exported: unset, the
    # CLI resolves ~/.son-of-anton, which for e-work and e-play IS their
    # service's home. That default is what makes `son-of-anton` in a terminal
    # land in the same session store as Signal, with nothing to keep in sync.
    environment.systemPackages = [ inputs.son-of-anton.packages.${pkgs.system}.default ];

    # The instances write into their own homes (ReadWritePaths is set per
    # instance by the upstream module) and read the flake they are built from.
    systemd.services = lib.mapAttrs' (
      name: _:
      lib.nameValuePair "son-of-anton-${name}" {
        serviceConfig = {
          ReadWritePaths = [ "/etc/nixos" ];

          # Every unit runs with group son-of-anton and the upstream module
          # creates each working directory 2770 <user>:son-of-anton, so DAC
          # alone lets any instance READ every other instance's project tree
          # and session store. Writes are already refused — ProtectSystem=strict
          # makes everything outside that instance's own ReadWritePaths
          # read-only — but a read is enough to hand one group's agent another
          # group's code, memories, and transcripts.
          #
          # Two instances now answer to people who are not the owner, so the
          # separation is made structural instead of resting on a mode bit that
          # tmpfiles reasserts on every activation: every OTHER instance's
          # state, home, and working directory becomes an empty, unreadable
          # mount inside this unit's namespace.
          #
          # "-" prefixed: a path that does not exist yet — a new instance whose
          # tmpfiles rules have not run — must not fail the unit.
          InaccessiblePaths = map (p: "-${p}") (
            lib.concatMap (
              other:
              [
                other.workingDirectory
                other.son-of-antonHome
              ]
              ++ lib.optional (other.stateDir != "") other.stateDir
            ) (lib.attrValues (lib.filterAttrs (n: _: n != name) cfg.instances))
          );
        };
      }
    ) cfg.instances;
  };
}
