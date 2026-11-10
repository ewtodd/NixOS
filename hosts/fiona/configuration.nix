{ pkgs, ... }:
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
    ./extra-packages.nix
  ];

  systemOptions = {
    graphics.intel.enable = true;
    deviceType.server.enable = true;
    services.ssh.enable = true;
    services.deploy.enable = true;
    services.binaryCache.consume = true;
    services.nodeExporter.enable = true;
    services.scheduledReboot.enable = true;
    services.scheduledReboot.calendar = "Sun *-*-* 05:30:00";
    # Sage-A1.5 and the RAG embeddings, for maitred on mu, on the A770M.
    services.eklow = {
      enable = true;
      lanExpose = true;
    };
    # The A770M holds one chat model, an llm-mode for each eklow instance (one today, `sage`); the last choice
    # starts at boot, and `llm-mode pause` frees the card for a window.
    services.llmMode = {
      enable = true;
      default = "sage";
      managers = [ "fiona" ];
    };
    # Title generation for maitred, on the Iris Xe.
    services.llamaCpp = {
      enable = true;
      lanExpose = true;
      models = {
        "little-titles" = {
          hf = "acon96/Little-Titles-GGUF:Q8_0";
          port = 8080;
          # The Iris Xe iGPU (Vulkan1 is the A770M), leaving the A770M to the
          # embeddings and eklow.
          device = "Vulkan0";
          ctxSize = 4096;
          chatTemplateFile = pkgs.writeText "little-titles.jinja" ''
            {%- set ns = namespace(system="Generate a short title describing the following user request.", user="") -%}
            {%- for m in messages -%}
              {%- if m.role == "system" -%}
                {%- set ns.system = m.content -%}
              {%- elif m.role == "user" -%}
                {%- set ns.user = ns.user + ("\n" if ns.user else "") + m.content -%}
              {%- endif -%}
            {%- endfor -%}
            {{- "<|im_start|>system\n" + ns.system + "<|im_end|>\n" -}}
            {{- "<|im_start|>user\n" + ns.user + "<|im_end|>\n" -}}
            {%- if add_generation_prompt -%}{{- "<|im_start|>assistant\n" -}}{%- endif -%}
          '';
        };
        # Reranking for maitred, on the Iris Xe beside the titles: eklow sizes its experts to the A770M's free
        # memory, so anything else on that card costs Sage decode speed.
        "qwen3-reranker" = {
          # ggml-org's conversion carries the classifier head (cls.output) and rerank template that llama.cpp's rank
          # pooling needs; a GGUF converted as the plain causal LM has neither and scores nonsense.
          path = "${pkgs.fetchurl {
            name = "qwen3-reranker-0.6b-q8_0.gguf";
            url = "https://huggingface.co/ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF/resolve/a02f48bb4f057028298c21fa033da2b30d7742d5/qwen3-reranker-0.6b-q8_0.gguf";
            sha256 = "22c9979ce4fbcdc5acdc310c6641c32797eff1aa980b8f7a2db8a8ea23429a48";
          }}";
          port = 8083;
          device = "Vulkan0";
          parallel = 2;
          ctxSize = 8192;
          # A query-document pair is scored in one ubatch (rank pooling cannot split one), so a slot's 4,096
          # positions are also the longest pair.
          batchSize = 4096;
          ubatchSize = 4096;
          specType = "none";
          extraFlags = [ "--reranking" ];
        };
      };
    };
    security.harden.enable = true;
  };

  users.users.fiona = {
    isNormalUser = true;
    description = "fiona";
    extraGroups = [
      "nixconfig"
      "networkmanager"
      "wheel"
      "video"
      "render"
    ];
    openssh.authorizedKeys.keys = personalKeys;
  };

  hardware.graphics.extraPackages = [ pkgs.intel-compute-runtime ];

  # Development on the A770M stops and restarts eklow and the llama servers without sudo.
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "fiona" &&
          /^(eklow(-[a-z0-9-]+)?|llama-(server-[a-z0-9-]+|embeddings))\.service$/.test(action.lookup("unit"))) {
        return polkit.Result.YES;
      }
    });
  '';

  time.timeZone = "America/Chicago";
  networking.hostName = "fiona";
  system.stateVersion = "26.11";
}
