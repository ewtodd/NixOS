{ lib, pkgs, osConfig ? null, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
  isEOwner = if osConfig != null then osConfig.systemOptions.owner.e.enable or false else false;
in
{
  home.file.".amethyst.yml" = lib.mkIf (isDarwin && isEOwner) {
    text = lib.generators.toYAML { } {
    layouts = [
      "tall"
      "wide"
      "fullscreen"
      "column"
    ];

    mod1 = [ "option" ];
    mod2 = [
      "option"
      "shift"
    ];

    # Focus left/right (opt+h/l)
    focus-ccw = {
      mod = "mod1";
      key = "h";
    };

    focus-cw = {
      mod = "mod1";
      key = "l";
    };

    # Toggle floating (opt+space)
    toggle-float = {
      mod = "mod1";
      key = "space";
    };

    # Fullscreen (opt+shift+f)
    select-fullscreen-layout = {
      mod = "mod2";
      key = "f";
    };

    shrink-main = {
      mod = "mod2";
      key = "r";
    };

    expand-main = {
      mod = "mod1";
      key = "r";
    };

    # Layout selection
    select-tall-layout = {
      mod = "mod1";
      key = "a";
    };

    disable-padding-on-builtin-display = false;
    window-margins = true;
    smart-window-margins = false;
    window-margin-size = 8;
    window-max-count = 0;
    window-minimum-height = 0;
    window-minimum-width = 0;
    floating = [ ];
    floating-is-blacklist = true;
    ignore-menu-bar = false;
    hide-menu-bar-icon = false;
    float-small-windows = true;
    mouse-follows-focus = false;
    focus-follows-mouse = true;
    mouse-swaps-windows = false;
    mouse-resizes-windows = false;
    enables-layout-hud = true;
    enables-layout-hud-on-space-change = false;
    use-canary-build = false;
    new-windows-to-main = false;
    follow-space-thrown-windows = true;
    window-resize-step = 5;
    screen-padding-left = 0;
    screen-padding-right = 0;
    screen-padding-top = 0;
    screen-padding-bottom = 0;
    restore-layouts-on-launch = true;
    debug-layout-info = false;
  };
  };
}
