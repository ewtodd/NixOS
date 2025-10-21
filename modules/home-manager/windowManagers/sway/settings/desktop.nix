{ pkgs, ... }:
let
  gapManager = pkgs.writeScriptBin "sway-gap-manager" ''
    #!${pkgs.python3.withPackages (ps: [ ps.i3ipc ])}/bin/python3

    import i3ipc

    i3 = i3ipc.Connection()
    print("Gap manager starting...")

    def manage_window_gaps(self=None, e=None):
        """Center single window at 50% width on DP-3"""
        try:
            focused = i3.get_tree().find_focused()
            workspace = focused.workspace()
            
            if workspace is None:
                return
                
            monitor = workspace.ipc_data['output']
            num_windows = len(workspace.nodes)
            
            if monitor != 'DP-3':
                return
            
            # DP-3: 3440x1440 @ 50% = 1720px wide
            # Gaps: (3440 - 1720) / 2 = 860px each side
            
            if num_windows == 1:
                i3.command('gaps left current set 860')
                i3.command('gaps right current set 860')
            else:
                i3.command('gaps left current set 0')
                i3.command('gaps right current set 0')
                
        except Exception as e:
            print(f"Error: {e}")

    i3.on('window::new', manage_window_gaps)
    i3.on('window::close', manage_window_gaps)
    i3.on('window::move', manage_window_gaps)
    i3.on('window::focus', manage_window_gaps)
    i3.on('workspace::init', manage_window_gaps)
    i3.on('workspace::empty', manage_window_gaps)

    manage_window_gaps()
    i3.main()
  '';
  toggle-float-smart = pkgs.writeShellScript "toggle-float-smart" ''
    # Get the focused window's floating state
    floating=$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused? == true) | .floating')

    if [ "$floating" = "user_on" ] || [ "$floating" = "auto_on" ]; then
        # If already floating, just toggle (disable floating)
        ${pkgs.sway}/bin/swaymsg floating toggle
    else
        # If tiled, enable floating, resize, and center
        ${pkgs.sway}/bin/swaymsg floating enable, resize set 45 ppt 75 ppt, move position center
    fi
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
        "Mod4+space" = "exec ${toggle-float-smart}";
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
