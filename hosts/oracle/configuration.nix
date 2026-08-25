{ ... }:
let
  personalKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDlbs+h9OqZMIAC6b3i4tUcXC4PidfBFEQNdwrLS8g9G ethan-desktop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOF2AcBcmt8acbIs5DwedIDZ0C02uKkMti5HJ1Mul/DH ethan-desktop-eplay"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvp7uwfajl11rFuFbS9TaWGVQ1de5vaaKATv7z76nsi ethan-laptop-ework"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4aIpszmO9PkX2gIoyAoJbOTgodqCrSw54W9IgmKINA ethan-laptop-eplay"
  ];
in
{
  imports = [
    ./hardware-configuration.nix
    ./environment.nix
  ];

  systemOptions = {
    graphics.asahi.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.nodeExporter.enable = true;
    services.litellmProxy.enable = true;
    services.searxng = {
      enable = true;
      # The son-of-anton gateway on e-desktop searches through this
      # instance, so it must be reachable on the LAN (loopback-only was
      # fine when the only consumer was on this host).
      listenAddress = "0.0.0.0";
      openFirewall = true;
    };
    services.openWebUI.enable = true;
    services.llamaSwap = {
      enable = true;
      # litellm (in its container on this host) routes the gateway's
      # session-title task to supra-title, so the swap API must be
      # reachable on the LAN — same trust model as son-of-anton's 8080.
      lanExpose = true;
      backend = "vulkan";
      # Always-resident embedding server for Open WebUI RAG. bge-m3 Q8
      # ~1.2GB on CPU (gpuLayers 0): asahi Vulkan is slow
      # for generation, but embeddings are tiny and latency-tolerant. Must
      # NOT share son-of-anton's GPUs — deepseek-v4-flash-full is solo and
      # needs every byte of VRAM. hfFile is explicit: the repo's file name
      # is not a quant tag, so -hf repo:quant would fail to resolve.
      embeddingModel = {
        hf = "ggml-org/bge-m3-Q8_0-GGUF";
        hfFile = "bge-m3-q8_0.gguf";
        pooling = "mean";
        ctxSize = 8192;
        gpuLayers = 0;
        port = 8082;
      };
      models = {
        # Session-title generation for the e-desktop gateway (via litellm).
        # Greedy sampling: a 50M model at llama.cpp's default temperature
        # loops ("Response Response Response ...").
        "supra-title" = {
          hf = "SupraLabs/supra-title-50M-pre-gguf:Q8_0";
          alwaysResident = true;
          ctxSize = 4096;
          extraFlags = [ "--temp 0" ];
        };
      };
    };
    security.harden.enable = true;
  };

  users.users.oracle = {
    isNormalUser = true;
    description = "oracle";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  time.timeZone = "America/Chicago";
  networking.hostName = "oracle";
  system.stateVersion = "26.11";

  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "10.0.0.4";
      system = "aarch64-linux";
      sshUser = "deploy";
      sshKey = "/etc/ssh/ssh_host_ed25519_key";
      maxJobs = 8;
      speedFactor = 10;
      supportedFeatures = [ "big-parallel" ];
    }
  ];

}
