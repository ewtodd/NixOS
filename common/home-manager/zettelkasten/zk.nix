{ config, ... }: {

  imports = [ ./templates.nix ./sync.nix ];

  programs.zk = {
    enable = true;
    settings = {
      # Specify the notebook directory
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
        link-format = "[[{{filename}}]]";
        link-drop-extension = true;
        link-encode-path = true;
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
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "idea.md";
          };
        };
        brainstorms = {
          paths = [ "ideas/brainstorms" ];
          note = {
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "brainstorm.md";
          };
        };
        concepts = {
          paths = [ "ideas/concepts" ];
          note = {
            filename = ''{{format-date now "timestamp"}}-{{slug title}}'';
            template = "concept.md";
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
        # Use groups for dynamic filenames
        daily = "zk new --group daily --no-input $HOME/zettelkasten/daily";
        task = "zk new --group tasks $HOME/zettelkasten/tasks/active";
        backlog = "zk new --group tasks $HOME/zettelkasten/tasks/backlog";
        project = "zk new --group projects $HOME/zettelkasten/projects";
        idea = "zk new --group ideas $HOME/zettelkasten/ideas";
        brainstorm =
          "zk new --group ideas $HOME/zettelkasten/ideas/brainstorms";
        concept = "zk new --group ideas $HOME/zettelkasten/ideas/concepts";
        meeting = "zk new --group meetings $HOME/zettelkasten/meetings";
        research = "zk new --group research $HOME/zettelkasten/research";
        howto = "zk new --group howtos $HOME/zettelkasten/reference/howtos";

        # Task management
        done = "zk edit --interactive --tag task --tag active";

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
    "${config.home.homeDirectory}/zettelkasten/ideas/brainstorms/.keep".text =
      "";
    "${config.home.homeDirectory}/zettelkasten/ideas/concepts/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/meetings/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/research/.keep".text = "";
    "${config.home.homeDirectory}/zettelkasten/howtos/.keep".text = "";
  };

}
