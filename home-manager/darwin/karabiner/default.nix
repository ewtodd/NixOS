{
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable or false else false;
in
{
  xdg.configFile."karabiner/karabiner.json" = lib.mkIf (isDarwin && isEOwner) {
    force = true;
    text = builtins.toJSON {
      global = {
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
      };

      profiles = [
        {
          name = "Default";
          selected = true;

          complex_modifications = {
            parameters = {
              basic.simultaneous_threshold_milliseconds = 50;
              basic.to_delayed_action_delay_milliseconds = 500;
              basic.to_if_alone_timeout_milliseconds = 200;
              basic.to_if_held_down_threshold_milliseconds = 200;
            };

            rules = [
              # Caps Lock -> Control in terminal apps
              {
                description = "Caps Lock to Escape/Control in terminals";
                manipulators = [
                  {
                    type = "basic";
                    conditions = [
                      {
                        type = "frontmost_application_if";
                        bundle_identifiers = [
                          "^com\\.apple\\.Terminal$"
                          "^com\\.googlecode\\.iterm2$"
                          "^io\\.alacritty$"
                          "^net\\.kovidgoyal\\.kitty$"
                          "^org\\.gnu\\.Emacs$"
                          "^co\\.zeit\\.hyper$"
                          "^com\\.github\\.wez\\.wezterm$"
                        ];
                      }
                    ];
                    from = {
                      key_code = "caps_lock";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to_if_alone = [
                      { key_code = "escape"; }
                    ];
                    to = [
                      { key_code = "left_control"; }
                    ];
                  }
                ];
              }

              # Caps Lock -> Command everywhere else
              {
                description = "Caps Lock to Escape/Command in non-terminals";
                manipulators = [
                  {
                    type = "basic";
                    conditions = [
                      {
                        type = "frontmost_application_unless";
                        bundle_identifiers = [
                          "^com\\.apple\\.Terminal$"
                          "^com\\.googlecode\\.iterm2$"
                          "^io\\.alacritty$"
                          "^net\\.kovidgoyal\\.kitty$"
                          "^org\\.gnu\\.Emacs$"
                          "^co\\.zeit\\.hyper$"
                          "^com\\.github\\.wez\\.wezterm$"
                        ];
                      }
                    ];
                    from = {
                      key_code = "caps_lock";
                      modifiers = {
                        optional = [ "any" ];
                      };
                    };
                    to_if_alone = [
                      { key_code = "escape"; }
                    ];
                    to = [
                      { key_code = "left_command"; }
                    ];
                  }
                ];
              }
            ];
          };
        }
      ];
    };
  };
}
