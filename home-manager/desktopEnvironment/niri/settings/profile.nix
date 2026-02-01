{
  config,
  lib,
  osConfig,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  inherit (inputs.niri-nix.lib) mkNiriKDL;
  deviceType = if (osConfig.systemOptions.deviceType.desktop.enable) then "desktop" else "laptop";
  stack-to-n = pkgs.writeText "stack.py" ''
    """
    Niri Stack-to-N for Vertical Displays

    Automatically stacks N windows vertically per column on portrait-oriented displays.
    When a new window opens, it is consumed into the previous column if that column has
    fewer than N windows, creating a vertical stack. Once a column reaches N windows,
    new windows start a new column, enabling horizontal scrolling.

    This mimics traditional tiling behavior on vertical displays while preserving Niri's
    default horizontal scrolling workflow on landscape displays.

    Features:
    - Auto-detects vertical (portrait) displays
    - Configurable stack size (N windows per column)
    - Optional column maximization
    - Zero focus disruption
    - Minimal performance overhead

    Author: Farokh Panahirad
    Repository: https://github.com/farokhraad/niri-stack-to-n
    License: MIT
    """

    import subprocess
    import json
    import logging
    import time
    from pathlib import Path


    # ============================================================================
    # Configuration
    # ============================================================================

    VERTICAL_STACK_N = 2  # Number of windows to stack per column
    MAXIMIZE_COLUMNS = True  # Auto-maximize columns to full width
    MAX_WIDTH_THRESHOLD = 0.5  # Window is maximized if width > 50% of display

    # Logging configuration
    ENABLE_LOGGING = True  # Set to False to disable logging completely
    LOG_FILE = '/tmp/niri_stack_to_n.log'
    LOG_LEVEL = logging.INFO  # Change to logging.DEBUG for more verbose output


    # ============================================================================
    # Setup Logging
    # ============================================================================

    if ENABLE_LOGGING:
        logging.basicConfig(
            filename=LOG_FILE,
            level=LOG_LEVEL,
            format='%(asctime)s [%(levelname)s] %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        logging.info('=' * 70)
        logging.info('Niri Stack-to-N Script Started')
        logging.info(f'Configuration: Stack={VERTICAL_STACK_N}, Maximize={MAXIMIZE_COLUMNS}')
        logging.info('=' * 70)
    else:
        # Disable all logging
        logging.disable(logging.CRITICAL)


    # ============================================================================
    # Niri IPC Functions
    # ============================================================================

    def niri_msg_json(cmd_args):
        """
        Execute a niri msg command and return JSON response.
        
        Args:
            cmd_args: List of command arguments
            
        Returns:
            Parsed JSON response or None on error
        """
        try:
            result = subprocess.check_output(['niri', 'msg', '--json'] + cmd_args)
            return json.loads(result)
        except subprocess.CalledProcessError as e:
            logging.error(f'Niri command failed: {e}')
            return None
        except json.JSONDecodeError as e:
            logging.error(f'Failed to parse JSON: {e}')
            return None
        except Exception as e:
            logging.error(f'Unexpected error: {e}')
            return None


    def niri_action(action):
        """
        Execute a niri action command.
        
        Args:
            action: Action string (e.g., 'maximize-column')
        """
        try:
            subprocess.run(
                ['niri', 'msg', 'action'] + action.split(),
                capture_output=True,
                timeout=1,
                check=True
            )
            logging.debug(f'Action executed: {action}')
        except subprocess.TimeoutExpired:
            logging.warning(f'Action timeout: {action}')
        except subprocess.CalledProcessError as e:
            logging.warning(f'Action failed: {action} - {e}')
        except Exception as e:
            logging.error(f'Unexpected error executing action: {e}')


    # ============================================================================
    # Display and Workspace Detection
    # ============================================================================

    def get_vertical_workspaces_with_widths():
        """
        Detect vertical (portrait) displays and return their workspaces.
        
        Returns:
            dict: {workspace_id: output_width} for vertical displays
        """
        outputs = niri_msg_json(['outputs']) or {}
        workspaces = niri_msg_json(['workspaces']) or []
        
        vertical_ws = {}
        vertical_count = 0
        
        for output in outputs.values():
            logical = output.get('logical', {})
            width = logical.get('width', 0)
            height = logical.get('height', 0)
            
            # Check if display is portrait (vertical)
            if width < height:
                output_name = output['name']
                vertical_count += 1
                logging.info(f'Detected vertical display: {output_name} ({width}x{height})')
                
                for ws in workspaces:
                    if ws.get('output') == output_name:
                        vertical_ws[ws['id']] = width
                        logging.debug(f'  Workspace {ws["id"]} on {output_name}')
        
        if vertical_count == 0:
            logging.warning('No vertical displays detected')
        
        return vertical_ws


    # ============================================================================
    # Window State Functions
    # ============================================================================

    def get_focused_window_on_workspace(workspace_id):
        """
        Get the currently focused window on a specific workspace.
        
        Args:
            workspace_id: ID of the workspace
            
        Returns:
            Window dict or None
        """
        windows = niri_msg_json(['windows']) or []
        
        for w in windows:
            if (w.get('workspace_id') == workspace_id and 
                w.get('is_focused') and 
                not w.get('is_floating', False)):
                return w
        
        return None


    def is_window_maximized(window, output_width):
        """
        Check if a window is maximized based on width threshold.
        
        Args:
            window: Window dict
            output_width: Width of the output display
            
        Returns:
            bool: True if window is considered maximized
        """
        if not window or not output_width:
            return False
        
        window_width = window.get('layout', {}).get('window_size', [0, 0])[0]
        is_max = (window_width / output_width) > MAX_WIDTH_THRESHOLD
        
        if is_max:
            logging.debug(f'Window {window.get("id")} is maximized ({window_width}/{output_width})')
        
        return is_max


    def get_focused_column_info(workspace_id):
        """
        Get information about the focused window's column.
        
        Args:
            workspace_id: ID of the workspace
            
        Returns:
            tuple: (column_index, previous_column_size, window_id)
        """
        windows = niri_msg_json(['windows']) or []
        
        focused = get_focused_window_on_workspace(workspace_id)
        if not focused:
            return (None, None, None)
        
        pos = focused.get('layout', {}).get('pos_in_scrolling_layout', [1, 1])
        col = pos[0]
        window_id = focused.get('id')
        
        # Count windows in previous column
        prev_col_size = sum(1 for win in windows
                          if win.get('workspace_id') == workspace_id
                          and not win.get('is_floating', False)
                          and win.get('layout', {}).get('pos_in_scrolling_layout', [0, 0])[0] == col - 1)
        
        logging.debug(f'Focused window {window_id} in column {col}, prev column has {prev_col_size} windows')
        
        return (col, prev_col_size, window_id)


    # ============================================================================
    # Column Management
    # ============================================================================

    def maximize_column_if_needed(workspace_id, output_width):
        """
        Maximize the focused column if not already maximized.
        
        Args:
            workspace_id: ID of the workspace
            output_width: Width of the output display
        """
        if not MAXIMIZE_COLUMNS:
            return
        
        focused = get_focused_window_on_workspace(workspace_id)
        if not focused:
            return
        
        if not is_window_maximized(focused, output_width):
            logging.info(f'Maximizing column for window {focused.get("id")}')
            niri_action('maximize-column')


    # ============================================================================
    # Main Loop
    # ============================================================================

    def main():
        """Main event loop for monitoring and managing windows."""
        
        # Detect vertical displays
        vertical_workspaces = get_vertical_workspaces_with_widths()
        
        if not vertical_workspaces:
            logging.error('No vertical displays found. Exiting.')
            if ENABLE_LOGGING:
                print('Error: No vertical displays detected. Check log at', LOG_FILE)
            else:
                print('Error: No vertical displays detected.')
            return 1
        
        logging.info(f'Monitoring {len(vertical_workspaces)} workspace(s) on vertical displays')
        
        # Track previous state to detect changes
        previous = {}
        
        try:
            while True:
                for ws_id, output_width in vertical_workspaces.items():
                    # Get current windows
                    windows = niri_msg_json(['windows']) or []
                    window_ids = tuple(sorted([
                        w['id'] for w in windows
                        if w.get('workspace_id') == ws_id
                        and not w.get('is_floating', False)
                    ]))
                    
                    # Skip if no change or no windows
                    if previous.get(ws_id) == window_ids or len(window_ids) == 0:
                        continue
                    
                    previous[ws_id] = window_ids
                    logging.debug(f'Window change detected on workspace {ws_id}: {len(window_ids)} windows')
                    
                    # Get focused column info
                    col, prev_size, new_window_id = get_focused_column_info(ws_id)
                    
                    # Check if we should consume into previous column
                    if col and col > 1 and prev_size and prev_size < VERTICAL_STACK_N:
                        logging.info(
                            f'Workspace {ws_id}: New window {new_window_id} in column {col}, '
                            f'previous column has {prev_size}/{VERTICAL_STACK_N} windows → consuming'
                        )
                        
                        # Consume window into previous column
                        niri_action(f'consume-or-expel-window-left --id {new_window_id}')
                        
                        # Maximize if needed
                        maximize_column_if_needed(ws_id, output_width)
                        
                    else:
                        if col:
                            logging.info(
                                f'Workspace {ws_id}: Window in column {col}, '
                                f'previous column full or first column → new column'
                            )
                            # Maximize new column if needed
                            maximize_column_if_needed(ws_id, output_width)
                
                # Poll every 10ms for near-instant response
                time.sleep(0.01)
                
        except KeyboardInterrupt:
            logging.info('Script stopped by user (Ctrl+C)')
            print('\nStopped')
            return 0
        except Exception as e:
            logging.error(f'Fatal error: {e}', exc_info=True)
            if ENABLE_LOGGING:
                print(f'Fatal error: {e}. Check log at {LOG_FILE}')
            else:
                print(f'Fatal error: {e}')
            return 1


    # ============================================================================
    # Entry Point
    # ============================================================================

    if __name__ == '__main__':
        exit(main())  
  '';

  createKittyPanelService = lib.mkIf (deviceType == "desktop") {
    systemd.user.services.kitty-background-panel = {
      Unit = {
        Description = "Kitty background panel with btop";
        After = [
          "graphical-session.target"
          "niri.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.kitty}/bin/kitten panel --edge=background --class kitty-background --output-name HDMI-A-1 btop";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  createStackService = lib.mkIf (deviceType == "desktop") {
    systemd.user.services.stack-to-n = {
      Unit = {
        Description = "Make vertical monitor in niri act like a regular tiling wm.";
        After = [
          "graphical-session.target"
          "niri.service"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.python3}/bin/python3 ${stack-to-n}";
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  primaryMonitor = if deviceType == "desktop" then "DP-3" else "eDP-1";
  secondaryMonitor =
    if deviceType == "desktop" then
      "HDMI-A-1"
    else
      (if deviceType == "laptop" then "HDMI-A-2" else "DP-3");
  alt-proportion = if deviceType == "desktop" then 0.5 else 0.75;

  workConfig = {
    workspace = [
      {
        _args = [ "b-chat" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "Slack";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "thunderbird";
        };
        open-on-workspace = "b-chat";
        default-column-width = {
          proportion = alt-proportion;
        };
        block-out-from = "screencast";
      }
      {
        match._props = {
          app-id = "firefox";
        };
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    layer-rule = [
      {
        match._props = {
          namespace = "kitty-background";
        };
        place-within-backdrop = true;
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.thunderbird-latest}/bin/thunderbird && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.slack}/bin/slack && niri msg action move-column-right" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];

  };

  playConfigBase = {
    workspace = [
      {
        _args = [ "c-chat" ];
        open-on-output = secondaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "firefox";
        };
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "signal";
        };
        open-on-workspace = "c-chat";
        default-column-width = {
          proportion = 1.0;
        };
      }
    ];
    layer-rule = [
      {
        match._props = {
          namespace = "kitty-background";
        };
        place-within-backdrop = true;
      }
    ];
    spawn-sh-at-startup = [
      [ "${pkgs.signal-desktop}/bin/signal-desktop --use-tray-icon" ]
      [ "${pkgs.protonvpn-gui}/bin/protonvpn-app --start-minimized" ]
    ];
  };

  playConfigDesktopAdditions = {
    workspace = [
      {
        _args = [ "b-media" ];
        open-on-output = primaryMonitor;
      }
    ];
    window-rule = [
      {
        match._props = {
          app-id = "steam";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
      {
        match._props = {
          app-id = "spotify";
        };
        open-on-workspace = "b-media";
        default-column-width = {
          proportion = alt-proportion;
        };
      }
    ];
    spawn-sh-at-startup = [
      [ "sleep 2 && ${pkgs.steam}/bin/steam && niri msg action move-column-left" ]
      [ "sleep 2 && ${pkgs.spotify}/bin/spotify && niri msg action move-column-right" ]
    ];
  };

  playConfig =
    if deviceType == "desktop" then
      {
        workspace = playConfigBase.workspace ++ playConfigDesktopAdditions.workspace;
        window-rule = playConfigBase.window-rule ++ playConfigDesktopAdditions.window-rule;
        spawn-sh-at-startup =
          playConfigBase.spawn-sh-at-startup ++ playConfigDesktopAdditions.spawn-sh-at-startup;
      }
    else
      playConfigBase;
in
{
  config = mkIf (osConfig.systemOptions.owner.e.enable) (mkMerge [
    createKittyPanelService
    createStackService
    {
      xdg.configFile."niri/profile.kdl".text =
        if config.Profile == "work" then
          mkNiriKDL workConfig
        else if config.Profile == "play" then
          mkNiriKDL playConfig
        else
          "";
    }
  ]);
}
