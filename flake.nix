{
  description = "DHCP client disclosing less identifying information";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-20.03";

  # Upstream source tree(s).
  inputs.dhcpcanon-src = { url = git+https://github.com/juga0/dhcpcanon.git; flake = false; };

  outputs = { self, nixpkgs, dhcpcanon-src }:
    let
      # Generate a user-friendly version numer.
      version = builtins.substring 0 8 dhcpcanon-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
      {
        # A Nixpkgs overlay.
        overlay = final: prev: {

          dhcpcanon = final.callPackage ./dhcpcanon.nix {
            src = dhcpcanon-src;
            inherit version;
          };

          kamene = final.callPackage ./kamene.nix {};
        };

        # Provide some binary packages for selected system types.
        packages = forAllSystems (
          system:
            {
              inherit (nixpkgsFor.${system}) dhcpcanon;
            }
        );

        # The default package for 'nix build'. This makes sense if the
        # flake provides only one package or there is a clear "main"
        # package.
        defaultPackage = forAllSystems (system: self.packages.${system}.dhcpcanon);

        # A NixOS module, if applicable (e.g. if the package provides a system service).
        nixosModules.dhcpcanon = (import ./module.nix) self.overlay;

        # Tests run by 'nix flake check' and by Hydra.
        checks = forAllSystems (
          system: {
            inherit (self.packages.${system}) dhcpcanon;

            vmTest = import ./vmtest.nix { inherit nixpkgs system; module = self.nixosModules.dhcpcanon; };
          }
        );
      };
}
