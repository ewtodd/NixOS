{ config, ... }: {

  imports = [ ./templates.nix ];

  programs.zk = {
    enable = true;
    settings = {
      notebook-dir = "${config.home.homeDirectory}/zettelkasten";

      note = {
        language = "en";
        default-title = "untitled";
        filename = ''{{format-date now "%Y-%m-%d"}}-{{slug title}}'';
        extension = "md";
        template = "default.md";
        id-charset = "alphanum";
        id-length = 8;
        id-case = "lower";
      };

      format = { markdown = { link-format = "wiki"; }; };

      tool = {
        editor = "nvim";
        fzf-preview = "bat -p --color always {-1}";
      };

      lsp = {
        diagnostics = {
          wiki-title = "hint";
          dead-link = "error";
        };
        completion = {
          note-label = "{{title}}"; # Use template to show actual title
          note-filter-text = "title body";
          note-detail =
            "{{title}} ({{filename}})"; # Show title and filename in details
        };
      };

      group = {
        daily = {
          paths = [ "daily" ];
          note = {
            filename = ''{{format-date now "%Y-%m-%d"}}'';
            template = "daily.md";
          };
        };
        tasks = {
          paths = [ "tasks/active" ];
          note = {
            filename = ''{{format-date now "%Y-%m-%d"}}-{{slug title}}'';
            template = "task.md";
          };
        };

        projects = {
          paths = [ "projects" ];
          note = {
            filename = "{{slug title}}";
            template = "project.md";
          };
        };
        ideas = {
          paths = [ "ideas" ];
          note = {
            filename = ''{{format-date now "%Y-%m-%d"}}-{{slug title}}'';
            template = "idea.md";
          };
        };
        meetings = {
          paths = [ "meetings" ];
          note = {
            filename = ''{{format-date now "%Y-%m-%d"}}-{{slug title}}'';
            template = "meeting.md";
          };
        };
        notes = {
          paths = [ "notes" ];
          note = {
            filename = ''{{format-date now "%Y-%m-%d"}}-{{slug title}}'';
            template = "note.md";
          };
        };
        howtos = {
          paths = [ "howtos" ];
          note = {
            filename = "{{slug title}}";
            template = "howto.md";
          };
        };
      };

      alias = {
        # No prompt - uses standard date format
        daily = "zk new daily --no-input";

        # Use shell expansion to handle arguments properly
        task = ''zk new tasks/active --no-input --title "$@"'';

        project = ''zk new projects --no-input --title "$@"'';
        idea = ''zk new ideas --no-input --title "$@"'';
        meeting = ''zk new meetings --no-input --title "$@"'';
        note = ''zk new notes --no-input --title "$@"'';
        howto = ''zk new howtos --no-input --title "$@"'';
        # Task management
        done = "zk edit  --tag task --tag active";

        # Navigation
        recent = "zk list --sort modified- --limit 10";
        todos = "zk list --tag task --tag active --sort priority-,created-";
      };
    };
  };

  home.file = {
    # Create directory structure
    "${config.home.homeDirectory}/zettelkasten/daily/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/tasks/active/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/tasks/complete/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/projects/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/ideas/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/meetings/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/notes/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/howtos/.keep".text = "";
  };

}
