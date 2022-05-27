{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "github:openfaas/faasd?ref=0.16.1";
      flake = false;
    };
    nixos-shell.url = "github:welteki/nixos-shell/improve-flake-support";
    nixos-shell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, utils, faasd-src, ... }@inputs:
    let
      faasdVersion = lock.nodes.faasd-src.original.ref;
      faasdRev = lock.nodes.faasd-src.locked.rev;
      lock = builtins.fromJSON (builtins.readFile ./flake.lock);

      supportedSystems = [
        "x86_64-linux"
      ];

      # NixOS configuration used for VM tests.
      faasdServer =
        { pkgs, ... }:
        {
          imports = [ self.nixosModules.faasd ];

          virtualisation.memorySize = 1024;

          services.faasd.enable = true;
        };
    in
    {
      overlay = final: prev:
        let
          inherit (final)
            lib
            buildGoModule
            fetchFromGitHub
            makeWrapper
            iptables;
        in
        {
          faasd-containerd = prev.containerd.overrideAttrs (old: rec {
            version = "1.6.4";

            src = fetchFromGitHub {
              owner = "containerd";
              repo = "containerd";
              rev = "v${version}";
              sha256 = "sha256-l/9jOvZ4nn/wy+XPRoT1lojfGvPEXhPz2FJjLpZ/EE8=";
            };

            outputs = lib.remove "man" old.outputs;

            buildPhase = ''
              runHook preBuild
              patchShebangs .
              make binaries "VERSION=v${version}" "REVISION=${src.rev}"
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm555 bin/* -t $out/bin
              installShellCompletion --bash contrib/autocomplete/ctr
              installShellCompletion --zsh --name _ctr contrib/autocomplete/zsh_autocomplete
              runHook postInstall
            '';
          });

          faasd-cni-plugins = prev.cni-plugins.overrideAttrs (old: rec {
            version = "0.9.1";

            src = fetchFromGitHub {
              owner = "containernetworking";
              repo = "plugins";
              rev = "v${version}";
              sha256 = "sha256-n+OtFXgFmW0xsGEtC6ua0qjdsJSbEjn08mAl5Z51Kp8=";
            };
          });

          containerd = final.faasd-containerd;
          cni-plugins = final.faasd-cni-plugins;

          faasd = buildGoModule {
            pname = "faasd";
            version = "${faasdVersion}";

            src = "${faasd-src}";

            vendorSha256 = null;

            CGO_ENABLED = 0;

            ldflags = [
              "-s"
              "-w"
              "-X main.Version=${faasdVersion}"
              "-X main.GitCommit=${faasdRev}"
            ];

            postInstall = ''
              mkdir -p $out/installation
              cp ./docker-compose.yaml $out/installation/docker-compose.yaml
              cp ./prometheus.yml $out/installation/prometheus.yml
              cp ./resolv.conf $out/installation/resolv.conf
            '';
          };
        };

      nixosModules.faasd = {
        imports = [ ./modules/faasd-module.nix ];
        nixpkgs.overlays = [ self.overlay ];
      };

      nixosConfigurations.faasd-vm = inputs.nixos-shell.lib.nixosShellSystem {
        system = "x86_64-linux";
        modules = [ faasdServer (args: { nixos-shell.mounts.mountHome = false; }) ];
      };

      templates = {
        hc-bootstrap = {
          path = ./bootstrap/hetzner-cloud-terraform;
          description = "Bootstrap faasd on hetzner cloud";
        };
      };

    } // utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };

        nixos-shell = inputs.nixos-shell.defaultPackage.${system};
      in
      {
        packages = {
          inherit (pkgs) faasd faasd-containerd faasd-cni-plugins;
        };

        defaultPackage = self.packages.${system}.faasd;

        devShells.faasd-vm = pkgs.mkShell {
          buildInputs = [
            nixos-shell
            pkgs.faas-cli
          ];
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            nixos-shell
            pkgs.faas-cli

            pkgs.nixpkgs-fmt
          ];
        };
      });
}
