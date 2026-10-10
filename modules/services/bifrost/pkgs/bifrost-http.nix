# Adapted from upstream nix/packages/bifrost-http.nix at the revision pinned by
# the `bifrost` flake input. Kept in-repo so the Go vendor hash and the
# build-platform Go selection are explicit; re-sync when bumping Bifrost. The
# functional differences are `go` (upstream's cross set would hand the helper
# the target compiler), `vendorHash`, and bifrost-gomod-tidy.diff, which makes
# the pinned Bifrost's go.mod/go.sum consistent with the local sibling-module
# replaces.
{
  pkgs,
  lib,
  src,
  version,
  bifrost-ui,
}:
let
  # pkgs.buildGoModule defaults to Go 1.26; Bifrost's go.mod requires 1.27.
  # In a cross set pkgs.go_1_27 is the target compiler, which cannot run on the
  # build host, so take the build-platform one.
  buildGoModule = pkgs.callPackage "${pkgs.path}/pkgs/build-support/go/module.nix" {
    go = pkgs.buildPackages.go_1_27 or pkgs.buildPackages.go;
  };
in
buildGoModule {
  pname = "bifrost-http";
  inherit version src;

  modRoot = "transports";
  subPackages = [ "bifrost-http" ];
  vendorHash = "sha256-TYoYIORfantTgAQkVNz5sbnTQDqpXkDLdkMltcfo10A=";

  # The source patches and the go.mod/go.sum patch all affect the vendored
  # tree, so the vendorHash above follows them and must be re-pinned whenever
  # any of them changes:
  #  - forward local servers' own window fields (vLLM max_model_len, llama.cpp
  #    meta.n_ctx, gufo top-level context_length) so the context probe sees
  #    them;
  #  - let a virtual key's description explain a refusal when the key is
  #    inactive, which is how the friend key's active-hours message reaches
  #    the client (the Bifrost module toggles its is_active on a timer);
  #  - forward captured extra params to custom providers, whose upstream may
  #    accept fields Bifrost does not model (e.g. a vLLM chat_template_kwargs);
  #    the x-bf-passthrough-extra-params header still gates normal providers;
  #  - teach the name-based xhigh ladder that the local Qwen3.8 routes (vLLM,
  #    llama.cpp/gufo) accept "xhigh": with no datasheet row the fallback snaps
  #    xhigh down to high, which those servers reject with HTTP 400;
  #  - resolve the sibling-module requires against the local checkout and
  #    complete go.sum so `go mod vendor` works on Go 1.27.
  patches = [
    ./bifrost-http-context-window.diff
    ./bifrost-vk-inactive-message.diff
    ./bifrost-custom-provider-extra-params.diff
    ./bifrost-xhigh-base-effort.diff
    ./bifrost-gomod-tidy.diff
  ];

  doCheck = false;

  env = {
    CGO_ENABLED = "1";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    gcc
  ];
  buildInputs = [ pkgs.sqlite ];

  preBuild = ''
    # Provide UI assets for //go:embed all:ui
    rm -rf bifrost-http/ui
    mkdir -p bifrost-http/ui
    if [ -d "${bifrost-ui}/ui" ]; then
      cp -R --no-preserve=mode,ownership,timestamps "${bifrost-ui}/ui/." bifrost-http/ui/
    else
      printf '%s\n' '<!doctype html><meta charset="utf-8"><title>Bifrost</title>' > bifrost-http/ui/index.html
    fi
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
  ];

  meta = {
    mainProgram = "bifrost-http";
    description = "Bifrost HTTP gateway";
    homepage = "https://github.com/maximhq/bifrost";
    license = lib.licenses.asl20;
  };
}
