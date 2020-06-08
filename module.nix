overlay:

{ pkgs, lib, config, ... }:

with lib;

{
  options = with types; {
    services.dhcpcanon = mkOption {
      default = {};
      description = ''
        Attribute set of interfaces for which to enable dhcpcanon, a DHCP client
        that discloses less identifying information.
      '';
      example = literalExample ''
        {
          eth0.enable = true;
        }
      '';
      type = attrsOf (
        submodule (
          { name, ... }: {
            options = {
              enable = mkEnableOption "dhcpcanon for this interface";

              extraOpts = mkOption {
                type = listOf str;
                default = [];
                example = [ "--delay_selecting" ];
                description = ''
                  Additional command line options to pass to <command>dhcpcanon</command>.
                '';
              };
            };
          }
        )
      );
    };
  };

  config = let
    mkCanonService = iface: opts: {
      description = "DHCP client Anonymity Profile";
      after = [ "systemd-udev-settle.service" "resolvconf.service" ];
      before = [ "network-online.target" ];
      wants = [ "network.target" "systemd-udev-settle.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.dhcpcanon}/bin/dhcpcanon ${concatStringsSep " " opts.extraOpts} ${iface}";
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];

        # avoid duplicate log messages
        StandardOutput = "null";

        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/etc/resolv.conf" "/run/resolvconf" ];

        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
      };
    };
  in
    {
      nixpkgs.overlays = [ overlay ];

      systemd.services = mapAttrs' (
        iface: opts:
          nameValuePair "dhcpcanon-${iface}" (mkCanonService iface opts)
      ) config.services.dhcpcanon;
    };
}
