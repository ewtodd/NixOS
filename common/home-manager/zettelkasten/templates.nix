{ ... }: {

  home.file = {
    ".config/zk/templates/default.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** 

      ## Content


    '';

    ".config/zk/templates/task.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Due:** 
      **Priority:** medium
      **Status:** active
      **Project:** [[]]
      **Tags:** #task #active

      ## Description



      ## Acceptance Criteria

      - [ ] 

      ## Related


    '';

    ".config/zk/templates/project.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Status:** planning
      **Tags:** #project

      ## Overview



      ## Current Tasks



      ## Related Ideas



      ## Meeting Notes


    '';

    ".config/zk/templates/idea.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** #idea

      ## Core Concept



      ## Potential Applications



      ## Related Projects



      ## Next Steps

      - [ ] 
    '';

    ".config/zk/templates/brainstorm.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** #brainstorm #idea

      ## Problem/Challenge



      ## Ideas

      - 
      - 

      ## Related Projects



      ## Action Items

      - [ ] 
    '';

    ".config/zk/templates/concept.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** #concept #idea

      ## Definition



      ## Examples



      ## Applications



      ## Related Concepts


    '';

    ".config/zk/templates/daily.md".text = ''
      # {{format-date now "Monday, January 2, 2006"}}

      **Date:** {{format-date now "2006-01-02"}}
      **Tags:** #daily

      ## Today's Focus



      ## Tasks

      - [ ] 

      ## Ideas & Insights



      ## Project Updates


    '';

    ".config/zk/templates/meeting.md".text = ''
      # {{title}}

      **Date:** {{format-date now "2006-01-02 15:04"}}
      **Attendees:** 
      **Project:** [[]]
      **Tags:** #meeting

      ## Agenda



      ## Discussion



      ## Action Items

      - [ ] 

      ## Related Tasks


    '';

    ".config/zk/templates/research.md".text = ''
      # {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** #research

      ## Research Question



      ## Findings



      ## Related Projects



      ## Next Steps

      - [ ] 
    '';

    ".config/zk/templates/howto.md".text = ''
      # How to {{title}}

      **Created:** {{format-date now "2006-01-02 15:04"}}
      **Tags:** #howto #reference

      ## Steps

      1. 
      2. 

      ## Tips



      ## Related Projects


    '';
  };
}
