{ nixpkgs, system, module }:

with import (nixpkgs + "/nixos/lib/testing-python.nix") {
  inherit system;
};

makeTest {
  nodes = {
    client = { pkgs, lib, ... }: {
      virtualisation.vlans = [ 1 2 ];

      networking.interfaces.eth1.useDHCP = false;
      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [];

      imports = [ module ];

      services.dhcpcanon."eth1".enable = true;
    };

    server = { pkgs, lib, ... }: {
      virtualisation.vlans = [ 1 2 ];

      networking.interfaces.eth1.ipv4.addresses = lib.mkForce [
        { address = "192.168.42.1"; prefixLength = 24; }
      ];

      services.dhcpd4 = {
        enable = true;
        interfaces = [ "eth1" ];
        extraConfig = ''
          subnet 192.168.42.0 netmask 255.255.255.0 {
            range 192.168.42.100 192.168.42.200;
            option routers 192.168.42.1;
            option domain-name-servers 8.1.8.1;
          }
        '';
      };

    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("dhcpd4.service")
    client.wait_for_unit("dhcpcanon-eth1.service")
    client.wait_until_succeeds("ip addr show dev eth1 | fgrep 'inet 192.168.42.'")

    assert "(eth1) state changed REQUESTING -> bound" in client.succeed(
        "journalctl -b -u dhcpcanon-eth1 -o cat"
    )
    client.wait_until_succeeds("fgrep 'nameserver 8.1.8.1' /etc/resolv.conf")
    assert "DHCPACK" in server.succeed("journalctl -b -u dhcpd4 -o cat")
  '';
}
