{
  description = "Bootstrap faasd on hetzner cloud using terraform and deploy-rs";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    faasd.url = "github:welteki/faasd-nix";
  };

  outputs = { self, nixpkgs, deploy-rs, utils, faasd }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.faasd = nixosSystem {
        inherit system;
        modules = [
          ({ pkgs, ... }:
            {
              imports = [
                ./hetzner-cloud.nix
                faasd.nixosModules.faasd
              ];

              services.faasd.enable = true;
            })
        ];
      };

      deploy = {
        magicRollback = false;

        nodes.faasd = {
          hostname = "";
          profiles.system.user = "root";
          profiles.system.path =
            deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.faasd;
        };
      };
    } // utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      {
        devShell = pkgs.mkShell {
          buildInputs = [
            (pkgs.terraform.withPlugins
              (p: with p; [ hcloud ]))
            deploy-rs.packages.${system}.deploy-rs
          ];
        };
      }
    );
}
