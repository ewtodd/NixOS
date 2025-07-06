{ lib, python3Packages, fetchFromGitHub, libusb1 }:

python3Packages.buildPythonApplication rec {
  pname = "mtkclient";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "bkerler";
    repo = "mtkclient";
    rev = "3093e652339352dca0806b9f3d6a2b4384a992ae";
    hash = "sha256-7fCX7NyvNAlz6ikGjHjoXblHfNrl6PUnG2jHfit71vk=";
  };
  format = "pyproject";
  nativeBuildInputs = with python3Packages; [ hatchling ];
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
    fusepy
    mock
    pycryptodomex
    pyside6
    shiboken6
  ];
  buildInputs = [ libusb1 ];

  doCheck = false;

  postInstall = ''
        # Create desktop entry for mtk_gui
        mkdir -p $out/share/applications
        cat > $out/share/applications/mtkclient-gui.desktop << EOF
    [Desktop Entry]
    Name=MTKClient GUI
    Comment=MTK reverse engineering and flash tool (GUI)
    Exec=$out/bin/mtk_gui
    Icon=applications-development
    Terminal=false
    Type=Application
    Categories=Development;System;
    Keywords=mtk;flash;android;mediatek;
    StartupNotify=true
    EOF
  '';
  meta = with lib; {
    description = "MTK reverse engineering and flash tool";
    homepage = "https://github.com/bkerler/mtkclient";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
