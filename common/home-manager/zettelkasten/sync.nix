{ config, pkgs, ... }: {

  # Custom systemd service for git sync
  systemd.user.services.zettelkasten-sync = {
    Unit = {
      Description = "Sync zettelkasten to git repository";
      After = [ "network.target" ];
    };
    Service = {
      Type = "oneshot";
      WorkingDirectory = "${config.home.homeDirectory}/zettelkasten";
      ExecStart = pkgs.writeShellScript "zettelkasten-sync" ''
        set -e

        # Check if we're in a git repository
        if [ ! -d .git ]; then
          echo "Not a git repository, skipping sync"
          exit 0
        fi

        # Add all changes
        ${pkgs.git}/bin/git add .

        # Only commit if there are changes
        if ! ${pkgs.git}/bin/git diff --cached --quiet; then
          ${pkgs.git}/bin/git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
          ${pkgs.git}/bin/git push
        else
          echo "No changes to commit"
        fi
      '';
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # Timer to run the sync service periodically
  systemd.user.timers.zettelkasten-sync = {
    Unit = {
      Description = "Timer for zettelkasten sync";
      Requires = [ "zettelkasten-sync.service" ];
    };
    Timer = {
      OnCalendar = "*:0/15"; # Every 15 minutes
      Persistent = true;
      RandomizedDelaySec = "5min"; # Add some randomization
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };

}
