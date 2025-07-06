{ lib, python3Packages, fetchFromGitHub, libusb1 }:

python3Packages.buildPythonApplication rec {
  pname = "mtkclient";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "mtkclient";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  propagatedBuildInputs = with python3Packages; [
    pyusb
    pyserial
    pycryptodome
    lxml
    colorama
    capstone
    keystone-engine
    unicorn
    requests
  ];

  buildInputs = [ libusb1 ];

  # Skip tests as they require hardware
  doCheck = false;

  # Install the main script
  postInstall = ''
    mkdir -p $out/bin
    cp $src/mtk $out/bin/mtkclient
    chmod +x $out/bin/mtkclient
  '';

  meta = with lib; {
    description = "MTK reverse engineering and flash tool";
    homepage = "https://github.com/bkerler/mtkclient";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
