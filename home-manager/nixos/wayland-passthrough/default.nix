{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  isLinux = pkgs.stdenv.isLinux;
  # Check if we're in a VM (Lima VMs on Darwin)
  isVM = if osConfig != null then (osConfig.networking.hostName or "") == "e-work-container" || (osConfig.networking.hostName or "") == "e-play-container" else false;
in
lib.mkIf (isLinux && isVM) {
  # Configure Wayland display for cocoa-way passthrough
  home.sessionVariables = {
    # cocoa-way creates a Wayland socket that we can connect to
    WAYLAND_DISPLAY = "wayland-0";
    # Ensure XDG runtime dir is set
    XDG_RUNTIME_DIR = "/run/user/1000";
  };

  # systemd user services for Wayland apps
  systemd.user.services = {
    # Service to wait for cocoa-way socket
    wayland-socket-wait = {
      Unit = {
        Description = "Wait for cocoa-way Wayland socket from Darwin host";
        Before = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while [ ! -e $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY ]; do sleep 1; done'";
        TimeoutStartSec = "30s";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };

  # Instructions for setting up cocoa-way on the Darwin host
  home.file.".config/vm-setup/README.md".text = ''
    # Wayland Graphics Passthrough Setup for Lima VM

    This VM is configured to use cocoa-way for Wayland graphics passthrough from the Darwin host.

    ## On the Darwin host:

    ### Option 1: Direct socket passthrough (simpler)
    ```bash
    # Start cocoa-way on Darwin
    cocoa-way --socket ~/wayland-0

    # Use limactl to copy socket into VM
    limactl copy ~/wayland-0 ${osConfig.networking.hostName or "vm"}:/tmp/wayland-0
    limactl shell ${osConfig.networking.hostName or "vm"} -- mkdir -p /run/user/1000
    limactl shell ${osConfig.networking.hostName or "vm"} -- cp /tmp/wayland-0 /run/user/1000/wayland-0
    ```

    ### Option 2: waypipe over network (recommended for performance)
    ```bash
    # On Darwin host:
    waypipe-darwin --socket tcp://0.0.0.0:9000 server

    # In VM:
    waypipe --socket tcp://192.168.5.2:9000 client niri
    ```

    The Darwin host is typically accessible at `192.168.5.2` from Lima VMs.

    ## Testing

    Once set up, test with:
    ```bash
    # Check Wayland socket exists
    ls -la /run/user/1000/wayland-0

    # Test with weston-info
    weston-info  # Should show Wayland compositor info

    # Start Niri compositor
    niri
    ```

    ## Auto-start setup

    To automatically start cocoa-way on Darwin boot, create a LaunchAgent:
    ```bash
    # ~/Library/LaunchAgents/com.cocoaway.plist
    # (This would be better managed through nix-darwin in the future)
    ```
  '';
}
