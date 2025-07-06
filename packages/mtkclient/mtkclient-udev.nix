{ stdenv, fetchFromGitHub, ... }:

stdenv.mkDerivation {
  name = "mtkclient-udev-rules";
  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "mtkclient";
    rev = "3093e652339352dca0806b9f3d6a2b4384a992ae";
    hash = "sha256-7fCX7NyvNAlz6ikGjHjoXblHfNrl6PUnG2jHfit71vk=";
  };

  installPhase = ''
    mkdir -p $out/lib/udev/rules.d
    cp $src/mtkclient/Setup/Linux/*.rules $out/lib/udev/rules.d/
  '';

  dontBuild = true;
  dontConfigure = true;
}
