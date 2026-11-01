{
  config,
  ...
}:
let
  colors = config.scheme;
  hex = name: "#${colors.${name}}";
  # Format 1 (m-prefixed keys): nixpkgs ships Noctalia 5.4.1, which predates
  # the versioned palette format and ignores its snake_case roles entirely.
  # Same semantic mapping dms-colors.json used; dark only, so light reuses it.
  dark = {
    mPrimary = hex "base0E";
    mOnPrimary = hex "base00";
    mSecondary = hex "base08";
    mOnSecondary = hex "base00";
    mTertiary = hex "base0D";
    mOnTertiary = hex "base00";
    mError = hex "base08";
    mOnError = hex "base00";
    mSurface = hex "base00";
    mOnSurface = hex "base05";
    mSurfaceVariant = hex "base01";
    mOnSurfaceVariant = hex "base05";
    mOutline = hex "base04";
    mShadow = hex "base00";
    mHover = hex "base02";
    mOnHover = hex "base05";
    terminal = {
      background = hex "base00";
      foreground = hex "base05";
      cursor = hex "base05";
      cursorText = hex "base00";
      selectionBg = hex "base02";
      selectionFg = hex "base05";
      normal = {
        black = hex "base00";
        red = hex "base08";
        green = hex "base0B";
        yellow = hex "base0A";
        blue = hex "base0D";
        magenta = hex "base0E";
        cyan = hex "base0C";
        white = hex "base05";
      };
      bright = {
        black = hex "base03";
        red = hex "base09";
        green = hex "base0B";
        yellow = hex "base0A";
        blue = hex "base0F";
        magenta = hex "base0E";
        cyan = hex "base0C";
        white = hex "base07";
      };
    };
  };
in
{
  programs.noctalia.customPalettes.fleet = {
    inherit dark;
  };
}
