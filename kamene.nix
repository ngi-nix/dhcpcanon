{ python3Packages, tcpdump, libdnet, libpcap }:

python3Packages.buildPythonApplication rec {
  pname = "kamene";
  version = "0.32";

  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "1niljk4v600gg9wq9ph1k375v4017yl7d0pk3rzplg6a17dr9zal";
  };

  propagatedBuildInputs = with python3Packages; [
    libdnet
    libpcap
    netifaces
  ];

  preBuild = ''
    substituteInPlace kamene/arch/cdnet.py --replace "find_library('dnet')" "'${libdnet}/lib/libdnet.so'"
    substituteInPlace kamene/arch/winpcapy.py --replace "find_library('pcap')" "'${libpcap}/lib/libpcap.so'"
  '';

  doCheck = false;

  meta = {
    homepage = "https://github.com/phaethon/kamene";
    description = "Network packet and pcap file manipulation security tool";
  };
}
