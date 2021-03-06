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
      nixosConfigurations.faasd =
        let
          configFile = ./config.json;
          config = builtins.fromJSON (builtins.readFile configFile);
        in
        nixosSystem {
          inherit system;
          modules = [
            ({ pkgs, ... }:
              {
                imports = [
                  ./hetzner-cloud.nix
                  faasd.nixosModules.faasd
                ];

                services.openssh = {
                  enable = true;
                  passwordAuthentication = false;
                };
                users.users.root.openssh.authorizedKeys.keys = [ config.ssh_public_key ];

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
      let
        pkgs = nixpkgs.legacyPackages.${system};
        terrafrom-withplugins = (pkgs.terraform.withPlugins (p: with p; [ hcloud ]));
        terraform = pkgs.writeShellScriptBin "terraform" ''
          flag=

          if [[ "$1" = "plan" || "$1" = "apply" ]]
            then flag="-var-file=$BOOTSTRAP_CONFIG"
          fi

          ${terrafrom-withplugins}/bin/terraform $* $flag
        '';
      in
      {
        devShell = pkgs.mkShell {
          shellHook = ''
            export BOOTSTRAP_CONFIG="./config.json"
          '';

          buildInputs = [
            terraform
            deploy-rs.packages.${system}.deploy-rs
          ];
        };

        checks = deploy-rs.lib.${system}.deployChecks self.deploy;
      }
    );
}
