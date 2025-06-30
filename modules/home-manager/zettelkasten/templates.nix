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

      ## Related Ideas

    '';

    "${templatepath}/templates/project.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Status:** planning
      **Tags:** #project

      ## Overview

      ## Active Action Items 

      - [ ]

      ## Completed Action Items

      - [ ]

      ## Related Ideas

    '';

    "${templatepath}/templates/idea.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #idea

      ## Core Concept

      ## Potential Applications

      ## Related Projects

      ## Action Items 

      - [ ] 

    '';

    "${templatepath}/templates/daily.md".text = ''
      # {{format-date now "full"}}

      **Date:** {{format-date now "full"}}
      **Tags:** #daily

      ## Today's Focus


      ## Ideas & Insights

      ## Project Updates

      ## Small Action Items 

      - [ ]

    '';

    "${templatepath}/templates/meeting.md".text = ''
      # {{title}}

      **Date:** {{format-date now "full"}}
      **Tags:** #meeting

      ## Agenda

      ## Discussion

      ## Related Projects

      ## Related Ideas

      ## Action Items

      - [ ] 

    '';

    "${templatepath}/templates/note.md".text = ''
      # {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #notes 

      ## Topic  

      ## Thoughts

      ## Related Howtos

      ## Related Projects 

      ## Action Items

      - [ ]

    '';

    "${templatepath}/templates/howto.md".text = ''
      # How to {{title}}

      **Created:** {{format-date now "full"}}
      **Tags:** #howto #reference

      ## Steps

      1. 

      2. 

      ## Notes 

      ## Related Projects

      ## Related Ideas
    '';

  };

}
