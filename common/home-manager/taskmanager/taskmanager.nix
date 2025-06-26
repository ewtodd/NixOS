{ config, pkgs, ... }: {

  programs.taskwarrior = {
    enable = true;
    dataLocation = "${config.xdg.dataHome}/task";
    colorTheme = "dark-256";

    config = {
      # Basic settings
      confirmation = false;
      verbose =
        "blank,footnote,label,new-id,affected,edit,special,project,sync,unwait";

      # TaskServer configuration
      taskd = {
        server = "taskserver.ethanwtodd.com:53589"; # Replace with your domain
        credentials =
          "personal/your-username/your-uuid-here"; # Will be set by export script
        certificate = "${config.xdg.dataHome}/task/keys/public.cert";
        key = "${config.xdg.dataHome}/task/keys/private.key";
        ca = "${config.xdg.dataHome}/task/keys/ca.cert";
      };

      color = let palette = config.colorScheme.palette;
      in {
        active = "rgb${palette.base0D}";
        due = "rgb${palette.base08}";
        overdue = "rgb${palette.base08} on_rgb${palette.base01}";
        project = "rgb${palette.base0E}";
        tag = "rgb${palette.base0A}";
        completed = "rgb${palette.base03}";
        deleted = "rgb${palette.base03}";

        # Priority colors
        "priority.H" = "rgb${palette.base08}";
        "priority.M" = "rgb${palette.base0A}";
        "priority.L" = "rgb${palette.base0B}";

        # Status colors
        pending = "rgb${palette.base05}";
        waiting = "rgb${palette.base04}";
        recurring = "rgb${palette.base0C}";
        blocked = "rgb${palette.base08} on_rgb${palette.base01}";
        blocking = "rgb${palette.base0F}";
        scheduled = "rgb${palette.base0C}";
        tagged = "rgb${palette.base0A}";
        "due.today" = "rgb${palette.base08} on_rgb${palette.base01}";
      };

      # UDA for note linking
      uda.note.type = "string";
      uda.note.label = "Note";
      uda.note.description = "Link to related note";

      # Reports
      report.next.columns = [
        "id"
        "start.age"
        "depends"
        "priority"
        "project"
        "tag"
        "recur"
        "scheduled.countdown"
        "due.relative"
        "until.remaining"
        "description"
        "urgency"
      ];
      report.next.labels = [
        "ID"
        "Active"
        "Deps"
        "P"
        "Project"
        "Tag"
        "Recur"
        "S"
        "Due"
        "Until"
        "Description"
        "Urg"
      ];
    };
  };

  # nb configuration
  home.file.".nbrc".text = ''
    export NB_DIR="$HOME/.nb"
    export NB_HEADER=0
    export NB_AUTO_SYNC=1
    export NB_DEFAULT_EXTENSION="md"
  '';

  # Initialize nb structure
  home.activation.setupNb = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.nb" ]; then
      $DRY_RUN_CMD ${pkgs.nb}/bin/nb init
      $DRY_RUN_CMD mkdir -p "$HOME/.nb/home/daily"
      $DRY_RUN_CMD mkdir -p "$HOME/.nb/home/projects"
      $DRY_RUN_CMD mkdir -p "$HOME/.nb/home/tasks"
    fi
  '';

  # TaskWarrior hooks for Git auto-sync
  home.file.".task/hooks/on-exit" = {
    text = ''
      #!/usr/bin/env bash
      cd "$HOME/.task"
      git add pending.data completed.data undo.data
      if ! git diff --cached --quiet; then
          git commit -m "TaskWarrior auto-sync: $(date)"
          git push origin main 2>/dev/null || true
      fi
    '';
    executable = true;
  };

  # Bash configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      t = "task";
      ta = "task add";
      tl = "task list";
      tn = "task next";
      tw = "taskwarrior-tui";
      ts = "task sync";

      na = "nb add";
      ns = "nb search";
      nb-sync = "cd ~/.nb && git pull && git push";

      daily = ''
        nb add "daily/$(date +%Y-%m-%d).md" --title "Daily Notes - $(date +%B %d, %Y)"'';
      tasks-today = "task list due:today";
    };

    sessionVariables = {
      TASKRC = "${config.xdg.configHome}/task/taskrc";
      TASKDATA = "${config.programs.taskwarrior.dataLocation}";
      NB_DIR = "${config.home.homeDirectory}/.nb";
      NB_AUTO_SYNC = "1";
    };

    bashrcExtra = ''
      # Function to link TaskWarrior task to nb note
      link_task_note() {
        if [ $# -ne 2 ]; then
          echo "Usage: link_task_note <task_id> <note_name>"
          return 1
        fi
        
        local task_id="$1"
        local note_name="$2"
        
        task "$task_id" annotate "Note: [[''${note_name}]]"
        
        if nb show "$note_name" >/dev/null 2>&1; then
          echo -e "\n## Related Task\n- Task ID: $task_id" | nb edit "$note_name" --content-append
        fi
        
        echo "Linked task $task_id to note $note_name"
      }

      # Daily workflow setup
      daily-setup() {
        echo "=== Daily Setup ==="
        
        task sync 2>/dev/null || echo "TaskWarrior sync failed or not configured"
        
        echo -e "\n Today's Tasks:"
        task list due:today 2>/dev/null || echo "No tasks due today"
        
        echo -e "\n  Next Tasks:"
        task next limit:5
        
        local today_note="daily/$(date +%Y-%m-%d).md"
        if ! nb show "$today_note" >/dev/null 2>&1; then
          nb add "$today_note" --title "Daily Notes - $(date +%B %d, %Y)" --content "# Daily Notes - $(date +%B %d, %Y)\n\n## Tasks\n\n## Notes\n\n## Reflections\n"
        fi
        
        echo -e "\n Today's note: $today_note"
      }
    '';
  };

}
