{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.systemOptions.nixos-vms;

  # Helper to generate Lima VM configuration YAML
  mkLimaConfig =
    {
      name,
      hostname,
      cpus ? 4,
      memory ? "8GiB",
      disk ? "100GiB",
    }:
    pkgs.writeText "${name}-lima.yaml" ''
      # Lima VM configuration for ${name}
      # Managed by nix-darwin

      vmType: "vz"
      os: "Linux"
      arch: "aarch64"

      images:
        # Use NixOS minimal ISO as base
        - location: "https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-aarch64-linux.iso"
          arch: "aarch64"

      cpus: ${toString cpus}
      memory: "${memory}"
      disk: "${disk}"

      # Share the Nix store from Darwin (read-only)
      mounts:
        - location: "/nix"
          mountPoint: "/nix"
          writable: false
        - location: "/etc/nixos"
          mountPoint: "/etc/nixos"
          writable: true
        - location: "~"
          mountPoint: "/mnt/darwin-home"
          writable: false

      # Port forwarding for Wayland
      portForwards:
        - guestPort: 5900  # For Wayland/VNC if needed
          hostPort: 0

      # Provision script to set up NixOS
      provision:
        - mode: system
          script: |
            #!/bin/bash
            set -eux -o pipefail

            # Install Nix if not present
            if ! command -v nix &> /dev/null; then
              curl -L https://nixos.org/nix/install | sh -s -- --daemon
              . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            fi

            # Enable flakes
            mkdir -p /etc/nix
            cat > /etc/nix/nix.conf <<EOF
            experimental-features = nix-command flakes
            substituters = https://cache.nixos.org
            trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
            EOF

            # Build and activate the NixOS configuration
            cd /etc/nixos
            nix build .#nixosConfigurations.${hostname}.config.system.build.toplevel --extra-experimental-features "nix-command flakes"
            ./result/bin/switch-to-configuration boot

      probes:
        - description: "SSH"
          script: |
            #!/bin/bash
            ssh -o ConnectTimeout=1 localhost echo "SSH is ready"
          hint: |
            Run 'limactl shell ${name}' to open a shell in the VM
    '';

  # Helper to create VM management scripts
  mkVMScripts =
    name: hostname:
    let
      limaConfig = mkLimaConfig {
        inherit name hostname;
      };
    in
    {
      create = pkgs.writeScriptBin "vm-${name}-create" ''
        #!${pkgs.bash}/bin/bash
        set -e
        echo "Creating Lima VM: ${name}"

        # Stop and delete if exists
        ${pkgs.lima}/bin/limactl stop ${name} 2>/dev/null || true
        ${pkgs.lima}/bin/limactl delete ${name} 2>/dev/null || true

        # Create new VM
        ${pkgs.lima}/bin/limactl create --name=${name} ${limaConfig}
        echo "VM ${name} created successfully"
      '';

      start = pkgs.writeScriptBin "vm-${name}-start" ''
        #!${pkgs.bash}/bin/bash
        set -e
        echo "Starting Lima VM: ${name}"
        ${pkgs.lima}/bin/limactl start ${name}
      '';

      stop = pkgs.writeScriptBin "vm-${name}-stop" ''
        #!${pkgs.bash}/bin/bash
        set -e
        echo "Stopping Lima VM: ${name}"
        ${pkgs.lima}/bin/limactl stop ${name}
      '';

      shell = pkgs.writeScriptBin "vm-${name}-shell" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.lima}/bin/limactl shell ${name}
      '';

      update = pkgs.writeScriptBin "vm-${name}-update" ''
        #!${pkgs.bash}/bin/bash
        set -e
        echo "Updating NixOS configuration in VM: ${name}"
        ${pkgs.lima}/bin/limactl shell ${name} -- bash -c "
          cd /etc/nixos
          nix build .#nixosConfigurations.${hostname}.config.system.build.toplevel --extra-experimental-features 'nix-command flakes'
          sudo ./result/bin/switch-to-configuration switch
        "
      '';

      rebuild = pkgs.writeScriptBin "vm-${name}-rebuild" ''
        #!${pkgs.bash}/bin/bash
        set -e
        echo "Rebuilding VM ${name} from scratch"
        vm-${name}-stop
        vm-${name}-create
        vm-${name}-start
        vm-${name}-update
      '';
    };
in
{
  # Options are declared in modules/common/default.nix
  config = mkIf cfg.enable {
    # Add Lima to system packages
    environment.systemPackages = with pkgs;
      [
        lima
        (writeScriptBin "vms-help" ''
          echo "NixOS Lima VM Management Commands:"
          echo ""
          echo "Global commands:"
          echo "  vms-list           - List all VMs"
          echo "  vms-start-all      - Start all configured VMs"
          echo "  vms-stop-all       - Stop all configured VMs"
          echo "  vms-update-all     - Update all VM configurations"
          echo ""
          ${optionalString cfg.work.enable ''
            echo "Work VM commands:"
            echo "  vm-work-create     - Create work VM"
            echo "  vm-work-start      - Start work VM"
            echo "  vm-work-stop       - Stop work VM"
            echo "  vm-work-shell      - Open shell in work VM"
            echo "  vm-work-update     - Update work VM configuration"
            echo "  vm-work-rebuild    - Rebuild work VM from scratch"
            echo ""
          ''}
          ${optionalString cfg.play.enable ''
            echo "Play VM commands:"
            echo "  vm-play-create     - Create play VM"
            echo "  vm-play-start      - Start play VM"
            echo "  vm-play-stop       - Stop play VM"
            echo "  vm-play-shell      - Open shell in play VM"
            echo "  vm-play-update     - Update play VM configuration"
            echo "  vm-play-rebuild    - Rebuild play VM from scratch"
            echo ""
          ''}
          echo "Direct lima commands are also available:"
          echo "  limactl list       - List all Lima VMs"
          echo "  limactl shell NAME - Open shell in specific VM"
        '')
        (writeScriptBin "vms-list" ''${pkgs.lima}/bin/limactl list'')
      ]
      ++ optionals cfg.work.enable (
        let
          scripts = mkVMScripts "work" "e-work-container";
        in
        [
          scripts.create
          scripts.start
          scripts.stop
          scripts.shell
          scripts.update
          scripts.rebuild
        ]
      )
      ++ optionals cfg.play.enable (
        let
          scripts = mkVMScripts "play" "e-play-container";
        in
        [
          scripts.create
          scripts.start
          scripts.stop
          scripts.shell
          scripts.update
          scripts.rebuild
        ]
      )
      ++ [
        (writeScriptBin "vms-start-all" ''
          ${optionalString cfg.work.enable "vm-work-start"}
          ${optionalString cfg.play.enable "vm-play-start"}
        '')
        (writeScriptBin "vms-stop-all" ''
          ${optionalString cfg.work.enable "vm-work-stop"}
          ${optionalString cfg.play.enable "vm-play-stop"}
        '')
        (writeScriptBin "vms-update-all" ''
          ${optionalString cfg.work.enable "vm-work-update"}
          ${optionalString cfg.play.enable "vm-play-update"}
        '')
      ];

    # LaunchDaemons for auto-starting VMs
    launchd.daemons = mkMerge [
      (mkIf (cfg.work.enable && cfg.work.autoStart) {
        "nixos-vm-work" = {
          script = "${pkgs.lima}/bin/limactl start work";
          serviceConfig = {
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/var/log/nixos-vm-work.log";
            StandardErrorPath = "/var/log/nixos-vm-work.log";
          };
        };
      })
      (mkIf (cfg.play.enable && cfg.play.autoStart) {
        "nixos-vm-play" = {
          script = "${pkgs.lima}/bin/limactl start play";
          serviceConfig = {
            RunAtLoad = true;
            KeepAlive = false;
            StandardOutPath = "/var/log/nixos-vm-play.log";
            StandardErrorPath = "/var/log/nixos-vm-play.log";
          };
        };
      })
    ];
  };
}
