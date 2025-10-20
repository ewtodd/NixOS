{ pkgs, ... }:
let
  gapManager = pkgs.writeScriptBin "sway-gap-manager" ''
    #!${pkgs.python3.withPackages (ps: [ ps.i3ipc ])}/bin/python3

    import i3ipc

    i3 = i3ipc.Connection()
    print("Gap manager starting (ignoring floating windows)...")

    def count_tiled_windows(workspace):
        """Count only tiled (non-floating) windows in workspace"""
        if workspace is None:
            return 0
        # workspace.nodes contains tiled windows
        # workspace.floating_nodes contains floating windows
        return len(workspace.nodes)

    def manage_window_gaps(self=None, e=None):
        """Center single tiled window at 50% width on DP-3"""
        try:
            focused = i3.get_tree().find_focused()
            workspace = focused.workspace()
            
            if workspace is None:
                return
                
            monitor = workspace.ipc_data['output']
            
            # Only manage gaps for DP-3
            if monitor != 'DP-3':
                return
            
            # Count only tiled windows (excludes floating)
            num_tiled_windows = count_tiled_windows(workspace)
            
            # DP-3: 3440x1440 @ 50% = 1720px wide
            # Gaps: (3440 - 1720) / 2 = 860px each side
            
            if num_tiled_windows == 1:
                # Center window with equal gaps on both sides
                i3.command('gaps left current set 860')
                i3.command('gaps right current set 860')
                print(f"Single tiled window: gaps enforced")
            elif num_tiled_windows > 1:
                # Multiple tiled windows, use normal tiling
                i3.command('gaps left current set 0')
                i3.command('gaps right current set 0')
                print(f"{num_tiled_windows} tiled windows: gaps removed")
            # If num_tiled_windows == 0, only floating windows exist, do nothing
                
        except Exception as e:
            print(f"Error in manage_window_gaps: {e}")

    # Only subscribe to window creation and close events
    i3.on('window::new', manage_window_gaps)
    i3.on('window::close', manage_window_gaps)
    i3.on('window::floating', manage_window_gaps)  # Handle floating toggle

    # Run initial check
    manage_window_gaps()

    # Start event loop
    i3.main()  
  '';

in {
  wayland.windowManager.sway = {
    enable = true;
    config = {
      # Output configuration
      output = {
        "HDMI-A-1" = {
          mode = "1920x1080@74.973Hz";
          position = "-1920,0";
        };
        "DP-3" = {
          resolution = "3440x1440@180.000Hz";
          position = "0,0";
        };
      };
      keybindings = {
        "Mod4+Shift+V" = "output HDMI-A-1 transform 90 position -1080 0";
      };
      startup = [{ command = "${gapManager}/bin/sway-gap-manager"; }];
    };
    extraConfig = ''
      # Thunderbird compose window
      for_window [app_id="thunderbird" title="^Write:"] floating enable, resize set 45 ppt 75 ppt, move position center

      # PulseAudio volume control
      for_window [title="Volume Control"] floating enable, resize set 45 ppt 75 ppt, move position center

      # Floating kitty terminal
      for_window [app_id="floatingkitty"] floating enable, resize set 45 ppt 75 ppt, move position center

      # Firefox file upload dialog
      for_window [app_id="firefox" title="File Upload"] floating enable, resize set 45 ppt 75 ppt, move position center

      # GEANT4 simulation window
      for_window [class="sim"] floating enable, resize set 45 ppt 75 ppt, move position center

      # ROOT plots 
      for_window [class="ROOT"] floating enable, resize set 45 ppt 75 ppt, move position center

      #GNOME disks 
      for_window [app_id="gnome-disks"] floating enable, resize set 45 ppt 75 ptt, move position center

      #XDG file upload
      for_window [app_id="xdg-desktop-portal-gtk"] floating enable, resize set 45 ppt 75 ppt, move position center
    '';

  };

}
