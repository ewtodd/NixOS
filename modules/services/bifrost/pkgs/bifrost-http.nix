# Adapted from upstream nix/packages/bifrost-http.nix at the revision pinned by
# the `bifrost` flake input. Kept in-repo so the Go vendor hash and the
# build-platform Go selection are explicit; re-sync when bumping Bifrost. The
# only functional differences are `go` (upstream's cross set would hand the
# helper the target compiler) and `vendorHash` (ours is for Go 1.27.1).
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

  # The transports module depends on the sibling modules by version; replace
  # them with the checkout's local copies for the hermetic source build.
  transportsLocalReplaces = ''
    if [ -f transports/go.mod ]; then
      cat >> transports/go.mod <<'EOF'

    replace github.com/maximhq/bifrost/core => ../core
    replace github.com/maximhq/bifrost/framework => ../framework
    replace github.com/maximhq/bifrost/plugins/governance => ../plugins/governance
    replace github.com/maximhq/bifrost/plugins/compat => ../plugins/compat
    replace github.com/maximhq/bifrost/plugins/logging => ../plugins/logging
    replace github.com/maximhq/bifrost/plugins/maxim => ../plugins/maxim
    replace github.com/maximhq/bifrost/plugins/otel => ../plugins/otel
    replace github.com/maximhq/bifrost/plugins/semanticcache => ../plugins/semanticcache
    replace github.com/maximhq/bifrost/plugins/telemetry => ../plugins/telemetry
    EOF
    fi
  '';
in
buildGoModule {
  pname = "bifrost-http";
  inherit version src;

  modRoot = "transports";
  subPackages = [ "bifrost-http" ];
  vendorHash = "sha256-GM3tV2hts0Xr+NKw/1Mu2o+4jjh6JDw0KTCqDDjv6JU=";

  doCheck = false;

  overrideModAttrs = final: prev: {
    postPatch = (prev.postPatch or "") + transportsLocalReplaces;
  };

  env = {
    CGO_ENABLED = "1";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    gcc
  ];
  buildInputs = [ pkgs.sqlite ];

  postPatch = transportsLocalReplaces;

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
