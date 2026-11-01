{
  config,
  lib,
  pkgs,
  ...
}:
let
  colors = config.scheme;
  width = 3840;
  height = 2160;
  # Centre of the canvas, and the factor that sizes the logomark to ~83% of the
  # wallpaper's height.
  cx = width / 2;
  cy = height / 2;
  scale = 0.45;

  # The official NixOS logomark is six hexagonal pieces with six-fold symmetry.
  # Each is filled with the base16 colour whose role matches the piece (red,
  # orange, yellow, green, blue, purple); base01 is the backdrop. The geometry
  # is fixed, so only the fills change per theme and the render is pixel-perfect
  # (rsvg computes correct edge coverage against the backdrop).
  pieces = [
    {
      color = colors.base08;
      points = "-624 249.4153162899184 -496 27.712812921102 64 997.6612651596733 -192 997.6612651596733 -320 775.9587617908571 -448 997.6612651596732 -576 997.6612651596732 -640 886.8100134752651 -448 554.2562584220408";
    }
    {
      color = colors.base09;
      points = "-528 -415.6921938165305 -272 -415.69219381653056 -832 554.2562584220408 -960 332.55375505322456 -832 110.85125168440817 -1088 110.85125168440794 -1152 0 -1088 -110.85125168440834 -704 -110.85125168440811";
    }
    {
      color = colors.base0A;
      points = "96 -665.1075101064489 224 -443.4050067376326 -896 -443.40500673763245 -768 -665.1075101064487 -512 -665.1075101064489 -640 -886.8100134752652 -576 -997.6612651596733 -448 -997.6612651596733 -256 -665.1075101064489";
    }
    {
      color = colors.base0B;
      points = "624 -249.41531628991848 496 -27.71281292110206 -64 -997.6612651596733 192 -997.6612651596733 320 -775.9587617908571 448 -997.6612651596732 576 -997.6612651596733 640 -886.8100134752652 448 -554.2562584220408";
    }
    {
      color = colors.base0D;
      points = "528 415.6921938165302 272 415.69219381653045 832 -554.2562584220411 960 -332.5537550532249 832 -110.85125168440845 1088 -110.8512516844084 1152 0 1088 110.85125168440794 704 110.85125168440788";
    }
    {
      color = colors.base0E;
      points = "-96 665.1075101064489 -224 443.40500673763256 896 443.4050067376328 768 665.107510106449 512 665.1075101064491 640 886.8100134752656 576 997.6612651596736 448 997.6612651596737 256 665.107510106449";
    }
  ];
  polygons = lib.concatStringsSep "\n" (
    lib.map (p: "        <polygon fill=\"#${p.color}\" points=\"${p.points}\"/>") pieces
  );

  svg = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${lib.toString width} ${lib.toString height}">
      <rect x="0" y="0" width="${lib.toString width}" height="${lib.toString height}" fill="#${colors.base01}"/>
      <g transform="translate(${lib.toString cx},${lib.toString cy}) scale(${lib.toString scale})">
    ${polygons}
      </g>
    </svg>
  '';

  # Emits a directory holding wallpaper.png so Noctalia's wallpaper.directory
  # (builtins.dirOf the path) contains the file it can find.
  wallpaper = pkgs.stdenvNoCC.mkDerivation {
    name = "nixos-wallpaper";
    src = pkgs.writeText "nixos-logomark.svg" svg;
    nativeBuildInputs = [ pkgs.librsvg ];
    dontConfigure = true;
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      rsvg-convert --width ${lib.toString width} --height ${lib.toString height} $src > $out/wallpaper.png
    '';
  };
in
{
  config = lib.mkIf (colors != null) {
    WallpaperPath = lib.mkDefault (wallpaper + "/wallpaper.png");
  };
}
