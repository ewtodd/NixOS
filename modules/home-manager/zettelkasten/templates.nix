{ config, ... }:

let templatepath = "${config.home.homeDirectory}/zettelkasten/.zk/";

in {

  home.file = {

    "${templatepath}/templates/default.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** 

      ## Content

    '';

    "${templatepath}/templates/task.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
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
    "${templatepath}/templates/backlog.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Due:** 
      **Priority:** medium
      **Status:** backlog 
      **Project:** [[]]
      **Tags:** #task #backlog

      ## Description

      ## Acceptance Criteria

      - [ ] 

      ## Related

    '';
    "${templatepath}/templates/project.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Status:** planning
      **Tags:** #project

      ## Overview

      ## Current Tasks

      ## Related Ideas

      ## Meeting Notes

    '';

    "${templatepath}/templates/idea.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #idea

      ## Core Concept

      ## Potential Applications

      ## Related Projects

      ## Next Steps

      - [ ] 

    '';

    "${templatepath}/templates/daily.md".text = ''
      # {{format-date now "full"}}

      **Date:** {{format-date now "medium"}}
      **Tags:** #daily

      ## Today's Focus

      ## Tasks

      - [ ] 

      ## Ideas & Insights

      ## Project Updates

    '';

    "${templatepath}/templates/meeting.md".text = ''
      # {{title}}

      **Date:** {{format-date now "full"}}
      **Attendees:** 
      **Project:** [[]]
      **Tags:** #meeting

      ## Agenda

      ## Discussion

      ## Action Items

      - [ ] 

      ## Related Tasks

    '';

    "${templatepath}/templates/note.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #notes 

      ## Topic  

      ## Thoughts

      ## Related Projects

    '';

    "${templatepath}/templates/howto.md".text = ''
      # How to {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #howto #reference

      ## Steps

      1. 

      2. 

      ## Tips

      ## Related Projects

    '';

  };

}
