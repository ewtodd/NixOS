{ config, pkgs, lib, ... }: {
  # Install packages
  home.packages = with pkgs; [ taskwarrior2 nb inotify-tools ];

  # TaskWarrior configuration
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior2;
    dataLocation = "${config.home.homeDirectory}/tasks-notes";
    config = {
      # Use Git sync instead of taskserver
      sync.server = "off";

      # Custom UDAs for nb integration
      uda.note.type = "string";
      uda.note.label = "Note";
      uda.note.default = "";

      # VIT requires explicit column definitions - this is the actual fix
      report.next.columns =
        "id,start.age,entry.age,depends,priority,project,tag,recur,scheduled.countdown,due.relative,until.remaining,description,urgency";
      report.next.labels =
        "ID,Active,Age,Deps,P,Project,Tag,Recur,S,Due,Until,Description,Urg";

      report.list.columns =
        "id,start.age,entry.age,depends.indicator,priority,project,tag,recur.indicator,scheduled.countdown,due.relative,until.remaining,description.count,urgency";
      report.list.labels =
        "ID,Active,Age,D,P,Project,Tag,R,S,Due,Until,Description,Urg";

      report.work.description = "Work tasks";
      report.work.filter = "project:work status:pending";
      report.work.columns =
        "id,start.age,entry.age,priority,project,tag,due.relative,description,urgency";
      report.work.labels = "ID,Active,Age,P,Project,Tag,Due,Description,Urg";

      report.play.description = "Play tasks";
      report.play.filter = "project:play status:pending";
      report.play.columns =
        "id,start.age,entry.age,priority,project,tag,due.relative,description,urgency";
      report.play.labels =
        "ID,Active,Age,P,Project,Tag,Due,Description,Urg"; # Color scheme
      color.active = "rgb013";
      color.due = "rgb500";
      color.overdue = "rgb550";
      color.project.work = "rgb030";
      color.project.play = "rgb300";
    };
  };

  # VIT configuration
  home.file.".vitrc".text = ''
    # VIT + nb integration keybindings

    # Note-taking integration
    map \cn=:!wr nb add --title "Task %TASKID: %TASKDESCRIPTION" --edit<Return>
    map \ce=:!wr nb edit task-%TASKID 2>/dev/null || nb add --title "Task %TASKID: %TASKDESCRIPTION" --edit<Return>
    map \cv=:!wr nb show task-%TASKID<Return>
    map \cl=:!wr nb list | grep -i "%TASKPROJECT"<Return>

    # Project notes
    map \cp=:!wr nb add --title "Project: %TASKPROJECT" --edit<Return>
    map \cP=:!wr nb list | grep -i "project.*%TASKPROJECT"<Return>

    # Quick capture from task context
    map \cc=:!wr nb add --content "Related to task %TASKID: %TASKDESCRIPTION" --edit<Return>

    # Search notes by task description
    map \cs=:!wr nb search "%TASKDESCRIPTION"<Return>

    # Daily workflow
    map \cd=:!wr nb add --title "Daily Notes $(date +%Y-%m-%d)" --edit<Return>
    map \cw=:!wr nb add --title "Weekly Review $(date +%Y-%m-%d)" --edit<Return>

    # Task context switching with notes
    map \ct=:!wr nb add --title "Task Context: %TASKID" --content "Switching to task: %TASKDESCRIPTION\nProject: %TASKPROJECT\nPriority: %TASKPRIORITY\n\nNotes:\n" --edit<Return>

    # Meeting notes linked to tasks
    map \cm=:!wr nb add --title "Meeting: %TASKPROJECT $(date +%Y-%m-%d)" --content "Related to task %TASKID: %TASKDESCRIPTION\n\n## Attendees\n\n## Agenda\n\n## Notes\n\n## Action Items\n" --edit<Return>

    # Export task list to nb
    map \cx=:!wr task export | nb add --title "Task Export $(date +%Y-%m-%d)" --type json<Return>

    # Browse all notes
    map \cb=:!wr nb browse<Return>

    # Today's journal
    map \cj=:!wr nb add --title "Journal $(date +%Y-%m-%d)" --edit<Return>

    # VIT display settings
    set default_command=next
    set vi_mode=1
    set mouse=0

    # Color scheme
    color_due_today=color_due
    color_overdue=color_overdue
    color_active=color_active
  '';

  # nb configuration
  home.file.".nbrc".text = ''
    export NB_DIR="${config.home.homeDirectory}/tasks-notes/notes"
    export NB_AUTO_SYNC=1
    export NB_COLOR_THEME=blacklight
    export EDITOR=nvim
  '';

  # Initialize directory structure
  home.activation.setupTasksNotes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        export PATH="${pkgs.git}/bin:${pkgs.taskwarrior3}/bin:${pkgs.nb}/bin:$PATH"
        
        TASKS_NOTES_DIR="$HOME/tasks-notes"
        
        if [ ! -d "$TASKS_NOTES_DIR" ]; then
          echo "Initializing tasks-notes directory..."
          $DRY_RUN_CMD mkdir -p "$TASKS_NOTES_DIR"
          $DRY_RUN_CMD mkdir -p "$TASKS_NOTES_DIR/notes"
          
          # Initialize git repository
          cd "$TASKS_NOTES_DIR"
          git init
          
          # Create .gitignore
          $DRY_RUN_CMD cat > .gitignore << 'EOF'
    # Temporary files
    *.tmp
    *~
    .#*
    \#*#

    # Backup files
    *.bak
    *.backup
    EOF
          
          # Initialize nb in the notes subdirectory
          cd notes
          nb init
          
          # Create initial notes structure
          nb add --title "README" --content "# Tasks and Notes

    This directory contains all task-related notes and documentation.

    ## Structure
    - Daily notes: Use \`nb add --title \"Daily Notes YYYY-MM-DD\"\`
    - Project notes: Use \`nb add --title \"Project: ProjectName\"\`
    - Task notes: Created automatically via VIT integration

    ## Usage
    - Use VIT for task management
    - Use nb for note-taking
    - Both sync automatically via Git
    " --filename "README.md"
          
          # Initial commit
          cd "$TASKS_NOTES_DIR"
          git add .
          git commit -m "Initial tasks-notes setup"
          
          echo "Tasks-notes initialized successfully"
        fi
  '';

  # Auto-sync service for tasks and notes
  systemd.user.services.tasks-notes-autopush = {
    Unit = {
      Description = "Auto-sync tasks and notes to Git";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
      Environment = [
        "TASKDATA=${config.home.homeDirectory}/tasks-notes"
        "NB_DIR=${config.home.homeDirectory}/tasks-notes/notes"
      ];
      ExecStart = pkgs.writeShellScript "tasks-notes-autopush" ''
        export PATH="${pkgs.git}/bin:${pkgs.inotify-tools}/bin:${pkgs.taskwarrior3}/bin:${pkgs.nb}/bin:$PATH"

        cd "$HOME/tasks-notes"

        # Watch for file changes
        inotifywait -m -r -e modify,create,delete,move --format '%w%f %e' . | while read file event; do
          # Skip temporary files and git files
          if [[ "$file" == *".git"* ]] || [[ "$file" == *"~"* ]] || [[ "$file" == *".tmp"* ]] || [[ "$file" == *"#"* ]]; then
            continue
          fi
          
          # Wait to batch changes
          sleep 3
          
          # Add all changes
          git add .
          
          # Only commit if there are changes
          if ! git diff --cached --quiet; then
            # Create descriptive commit message
            changed_files=$(git diff --cached --name-only | head -3 | tr '\n' ' ')
            commit_msg="Auto-sync: Updated $changed_files ($(date '+%H:%M'))"
            
            git commit -m "$commit_msg"
            
            # Push changes
            git push origin main 2>/dev/null || {
              echo "$(date): tasks-notes push failed" >> ~/.tasks-notes-sync.log
            }
          fi
        done
      '';
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # Periodic sync service
  systemd.user.services.tasks-notes-sync = {
    Unit = { Description = "Periodic sync for tasks and notes"; };
    Service = {
      Type = "oneshot";
      Environment = [
        "TASKDATA=${config.home.homeDirectory}/tasks-notes"
        "NB_DIR=${config.home.homeDirectory}/tasks-notes/notes"
      ];
      ExecStart = pkgs.writeShellScript "tasks-notes-sync" ''
        export PATH="${pkgs.git}/bin:${pkgs.taskwarrior3}/bin:${pkgs.nb}/bin:$PATH"

        echo "=== Syncing tasks and notes ==="

        cd "$HOME/tasks-notes"

        # Pull first to avoid conflicts
        git pull origin main 2>/dev/null || echo "Pull failed - may be offline"

        # Add and commit any local changes
        git add .
        if ! git diff --cached --quiet; then
            git commit -m "Scheduled sync: $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        # Push changes
        git push origin main 2>/dev/null || echo "Push failed - may be offline"

        echo "=== Tasks and notes sync complete ==="
      '';
    };
  };

  systemd.user.timers.tasks-notes-sync = {
    Unit = { Description = "Periodic sync timer for tasks and notes"; };
    Timer = {
      OnCalendar = "*:0/10"; # Every 10 minutes
      Persistent = true;
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };

  # Enhanced bash configuration
  programs.bash = {
    shellAliases = {
      # Main interfaces
      tasks = "vit";
      notes = "nb";

      # Workflow shortcuts
      work = "vit project:work";
      play = "vit project:play";

      # Quick capture
      capture = "nb add --edit";
      todo = "task add";

      # Daily workflow
      daily = "nb add --title 'Daily Notes $(date +%Y-%m-%d)' --edit && vit";
      journal = "nb add --title 'Journal $(date +%Y-%m-%d)' --edit";
      review = "nb add --title 'Daily Review $(date +%Y-%m-%d)' --edit && vit";

      # Sync commands
      "sync-all" = "systemctl --user start tasks-notes-sync";
      "sync-status" = "systemctl --user status tasks-notes-autopush";
    };

    sessionVariables = {
      TASKDATA = "${config.home.homeDirectory}/tasks-notes";
      NB_DIR = "${config.home.homeDirectory}/tasks-notes/notes";
      NB_AUTO_SYNC = "1";
    };

    bashrcExtra = ''
            # TaskWarrior + nb integration functions
            
            # Create task with associated note
            task-note() {
              if [ $# -eq 0 ]; then
                echo "Usage: task-note <task description>"
                return 1
              fi
              
              # Add task and capture ID
              local task_id=$(task add "$@" | grep -o 'Created task [0-9]*' | grep -o '[0-9]*')
              
              # Create associated note
              nb add --title "Task $task_id: $*" --edit
              
              # Open VIT to see the new task
              vit
            }
            
            # Search tasks and notes together
            search-all() {
              if [ $# -eq 0 ]; then
                echo "Usage: search-all <search term>"
                return 1
              fi
              
              echo "=== Tasks ==="
              task list description.contains:"$1"
              echo -e "\n=== Notes ==="
              nb search "$1"
            }
            
            # Project workflow
            project-setup() {
              if [ $# -eq 0 ]; then
                echo "Usage: project-setup <project_name>"
                return 1
              fi
              
              local project="$1"
              
              # Create project objective task
              task add "project:$project" "Complete $project project"
              
              # Create project notes
              nb add --title "Project: $project" --content "# $project Project

      ## Overview

      ## Tasks
      - [ ] Define scope
      - [ ] Break down into tasks

      ## Notes

      ## Resources
      " --edit
              
              # Open VIT filtered to this project
              vit project:"$project"
            }
            
            # Weekly review
            weekly-review() {
              local week_start=$(date -d 'last monday' '+%Y-%m-%d')
              local week_end=$(date -d 'next sunday' '+%Y-%m-%d')
              
              echo "=== Weekly Review: $week_start to $week_end ==="
              
              # Show completed tasks
              echo "Completed tasks:"
              task completed end.after:$week_start
              
              # Show pending tasks
              echo -e "\nPending tasks:"
              task list
              
              # Create weekly review note
              nb add --title "Weekly Review $week_start" --content "# Weekly Review: $week_start to $week_end

      ## Completed This Week
      $(task completed end.after:$week_start)

      ## Still Pending
      $(task list)

      ## Reflections

      ## Next Week Goals

      " --edit
            }
            
            # Task context with automatic note creation
            task-context() {
              if [ $# -eq 0 ]; then
                echo "Usage: task-context <task_id>"
                return 1
              fi
              
              local task_id="$1"
              local task_desc=$(task _get $task_id.description)
              local task_project=$(task _get $task_id.project)
              
              # Create context note
              nb add --title "Task Context: $task_id" --content "# Task Context: $task_id

      **Task:** $task_desc
      **Project:** $task_project
      **Started:** $(date)

      ## Context
      Why am I working on this now?

      ## Approach
      How will I tackle this?

      ## Notes

      ## Blockers

      ## Next Steps

      " --edit
              
              # Start the task
              task start $task_id
            }
    '';
  };
}
