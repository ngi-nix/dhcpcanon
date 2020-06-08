{ python3Packages
, pkg-config
, src
, version
, kamene
, resolvconfPath ? "/run/current-system/sw/bin/resolvconf"
}:

python3Packages.buildPythonApplication rec {
  pname = "dhcpcanon";
  inherit version src;

  nativeBuildInputs = [ pkg-config ];

  propagatedBuildInputs = with python3Packages; [
    attrs
    dbus-python
    netaddr
    lockfile
    pip
    pyroute2
    kamene
  ];

  checkInputs = with python3Packages; [
    pytest
    tox
    coverage
  ];

  preBuild = ''
    substituteInPlace setup.py \
        --replace '"dbus-python>=1.2",' "" \
        --replace "'scapy-python3>=0.20'," ""
    for F in $(grep -rl scapy .); do
      substituteInPlace $F --replace scapy kamene
    done
    substituteInPlace dhcpcanon/constants.py --replace "'/sbin/resolvconf'" "'${resolvconfPath}'"
  '';

  meta = {
    homepage = "https://github.com/juga0/dhcpcanon";
    description = "DHCP client disclosing less identifying information";
  };
}
