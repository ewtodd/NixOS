{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemOptions.services.flakeBump;

  bump = pkgs.writeShellApplication {
    name = "flake-bump";
    runtimeInputs = with pkgs; [
      config.nix.package
      git
      jq
      nvd
      vulnix
      coreutils
      findutils
      gnugrep
      gnused
    ];
    # The report's markdown puts backticks inside single-quoted printf formats.
    excludeShellChecks = [ "SC2016" ];
    text = builtins.readFile ./flake-bump.sh;
  };

  report = pkgs.writeShellApplication {
    name = "flake-bump-report";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
    ];
    text = builtins.readFile ./flake-bump-report.sh;
  };
in
{
  options.systemOptions.services.flakeBump = {
    enable = lib.mkEnableOption "the scheduled flake update: every input on a branch, every host built, a report for son-of-anton to review";
    user = lib.mkOption {
      type = lib.types.str;
      default = "e-work";
      description = ''
        Account that runs the update and whose son-of-anton instance reviews
        it: the review's pre-run script clears each report's PENDING marker, so
        it must own the state directory. Needs write access to the repo's .git.
      '';
    };
    repo = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
    };
    calendar = lib.mkOption {
      type = lib.types.str;
      default = "Sat *-*-* 01:00:00";
    };
    reviewHome = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/e-work/.son-of-anton";
      description = ''
        son-of-anton home whose scripts/ gets flake-bump-report.sh, the
        pre-run script of the cron job that reviews each run.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.flake-bump = {
      description = "Update every flake input on a branch and build every host";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      # The repo may belong to another member of its group: git refuses a repo
      # (or a worktree of it) owned by someone else unless it is listed as
      # safe, and the account may have no committer identity of its own.
      environment = {
        FLAKE_BUMP_REPO = cfg.repo;
        GIT_CONFIG_COUNT = "2";
        GIT_CONFIG_KEY_0 = "safe.directory";
        GIT_CONFIG_VALUE_0 = cfg.repo;
        GIT_CONFIG_KEY_1 = "safe.directory";
        GIT_CONFIG_VALUE_1 = "/var/lib/flake-bump/worktree";
        GIT_COMMITTER_NAME = "son-of-anton-bot";
        GIT_COMMITTER_EMAIL = "307402699+son-of-anton-bot@users.noreply.github.com";
      };
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        StateDirectory = "flake-bump";
        ExecStart = lib.getExe bump;
        Nice = 10;
      };
    };

    systemd.timers.flake-bump = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.calendar;
        Persistent = true;
      };
    };

    # cron refuses a script that resolves outside <home>/scripts, so a store
    # symlink will not do: a real file that execs the store copy, rewritten
    # (f+) at every boot and activation.
    systemd.tmpfiles.rules = lib.optionals (cfg.reviewHome != null) [
      "d ${cfg.reviewHome}/scripts 0700 ${cfg.user} - -"
      "f+ ${cfg.reviewHome}/scripts/flake-bump-report.sh 0700 ${cfg.user} - - exec ${lib.getExe report} /var/lib/flake-bump"
    ];
  };
}
