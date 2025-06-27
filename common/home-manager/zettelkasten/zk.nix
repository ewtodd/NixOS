{ config, ... }: {

  imports = [ ./templates.nix ./sync.nix ];

  programs.zk = {
    enable = true;
    settings = {
      notebook-dir = "${config.home.homeDirectory}/zettelkasten";

      note = {
        language = "en";
        default-title = "untitled";
        filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
        extension = "md";
        template = "default.md";
        id-charset = "alphanum";
        id-length = 8;
        id-case = "lower";
      };

      format.markdown = {
        link-format = "wiki";
        link-drop-extension = false;
        link-encode-path = false;
      };

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
          note-label = "title";
          note-filter-text = "title body";
          note-detail = "filename";
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
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "task.md";
          };
        };
        backlog = {
          paths = [ "tasks/backlog" ];
          note = {
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "backlog.md";
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
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
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
        research = {
          paths = [ "research" ];
          note = {
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "research.md";
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
        backlog = ''zk new tasks/backlog --no-input --title "$@"'';
        project = ''zk new projects --no-input --title "$@"'';
        idea = ''zk new ideas --no-input --title "$@"'';
        meeting = ''zk new meetings --no-input --title "$@"'';
        research = ''zk new research --no-input --title "$@"'';
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
    "${config.home.homeDirectory}/zettelkasten/tasks/backlog/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/projects/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/ideas/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/meetings/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/research/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/howtos/.keep".text = "";
  };

}
