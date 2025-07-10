{ lib, fetchFromGitHub, stdenv, systemd, meson, ninja, pkg-config
, wayland-scanner, scdoc, gdk-pixbuf, librsvg, wayland-protocols, libdrm
, libinput, cairo, pango, wayland, libGL, libxkbcommon, pcre2, json_c, libevdev
, xcbutilwm, wlroots_0_19, scenefx, testers, nixosTests
# Used by the NixOS module:
, isNixOS ? false, enableXWayland ? true
, systemdSupport ? lib.meta.availableOn stdenv.hostPlatform systemd
, trayEnabled ? systemdSupport }:

stdenv.mkDerivation (finalAttrs: {
  inherit enableXWayland isNixOS systemdSupport trayEnabled;

  pname = "swayfx-unwrapped";
  version = "git";

  src = lib.cleanSource ./.;

  strictDeps = true;

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [ meson ninja pkg-config wayland-scanner scdoc ];

  buildInputs = [
    libGL
    wayland
    libxkbcommon
    pcre2
    json_c
    libevdev
    pango
    cairo
    libinput
    gdk-pixbuf
    librsvg
    wayland-protocols
    libdrm
    wlroots_0_19
    # Remove scenefx from buildInputs - it will be a subproject
  ] ++ lib.optionals finalAttrs.enableXWayland [ xcbutilwm ];

  preConfigure = ''
    mkdir -p subprojects
    cp -R --no-preserve=mode,ownership ${./scenefx} subprojects/scenefx
    echo "Copied local scenefx source to subprojects"
  '';

  mesonFlags = let
    inherit (lib.strings) mesonEnable mesonOption;
    sd-bus-provider = if systemdSupport then "libsystemd" else "basu";
  in [
    (mesonOption "sd-bus-provider" sd-bus-provider)
    (mesonEnable "tray" finalAttrs.trayEnabled)
  ];

  passthru = {
    # Add the required providedSessions attribute
    providedSessions = [ "sway" ];

    tests = {
      basic = nixosTests.swayfx or null;
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
        command = "sway --version";
        version = "swayfx version ${finalAttrs.version}";
      };
    };
  };

  meta = {
    description = "Sway, but with eye candy!";
    homepage = "https://github.com/WillPower3309/swayfx";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ricarch97 ];
    platforms = lib.platforms.linux;
    mainProgram = "sway";
    longDescription = ''
      Fork of Sway, an incredible and one of the most well established Wayland
      compositors, and a drop-in replacement for the i3 window manager for X11.
      SwayFX adds extra options and effects to the original Sway, such as rounded corners,
      shadows and inactive window dimming to bring back some of the Picom X11
      compositor functionality, which was commonly used with the i3 window manager.
    '';
  };
})
