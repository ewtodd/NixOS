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
        filename = "{{format-date now 'timestamp'}}-{{slug title}}";
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
        shell = "/bin/bash";
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

      alias = {
        # Core note types
        daily = "zk new --no-input --template daily.md daily";
        task = "zk new --no-input --template task.md tasks/active";
        project = "zk new --no-input --template project.md projects";
        idea = "zk new --no-input --template idea.md ideas";
        brainstorm =
          "zk new --no-input --template brainstorm.md ideas/brainstorms";
        concept = "zk new --no-input --template concept.md ideas/concepts";
        meeting = "zk new --no-input --template meeting.md meetings";
        research = "zk new --no-input --template research.md research";
        howto = "zk new --no-input --template howto.md reference/howtos";

        # Task management
        done = "zk edit --interactive --tag task --tag active";
        backlog = "zk new --no-input --template task.md tasks/backlog";

        # Navigation
        recent = "zk list --sort modified- --limit 10";
        todos = "zk list --tag task --tag active --sort priority-,created-";
      };

      group = {
        daily = {
          paths = [ "daily" ];
          note = {
            filename = "{{format-date now '2006-01-02'}}";
            template = "daily.md";
          };
        };
        tasks = {
          paths = [ "tasks" ];
          note = {
            filename = "{{format-date now 'timestamp'}}-{{slug title}}";
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
            filename = "{{format-date now 'timestamp'}}-{{slug title}}";
            template = "idea.md";
          };
        };
        meetings = {
          paths = [ "meetings" ];
          note = {
            filename = "{{format-date now '2006-01-02'}}-{{slug title}}";
            template = "meeting.md";
          };
        };
        research = {
          paths = [ "research" ];
          note = {
            filename = "{{format-date now 'timestamp'}}-{{slug title}}";
            template = "research.md";
          };
        };
        reference = {
          paths = [ "reference" ];
          note = {
            filename = "{{slug title}}";
            template = "howto.md";
          };
        };
      };
    };
  };

}
