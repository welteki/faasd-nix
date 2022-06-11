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

  nixConfig.extra-substituters = [ "https://welteki.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "welteki.cachix.org-1:zb0txiNEbjq9Fx7svp4LhTgFIQHKSa5ESi7QlLFjjQY=" ];

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
            iptables
            dockerTools;

          inherit (dockerTools) pullImage;
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

          openfaas-images = {
            basic-auth = pullImage {
              imageName = "ghcr.io/openfaas/basic-auth";
              imageDigest = "sha256:e99c385f248ce9a6569bf262e3480ddbf317cd5982243fcc229ee1766d24eb5a";
              finalImageTag = "0.21.4";
              sha256 = "sha256-LyXZcK7bmc1B/QNdgvfNiL5t/5IpvnLKtFokBxRIMa4=";
            };

            gateway = pullImage {
              imageName = "ghcr.io/openfaas/gateway";
              imageDigest = "sha256:57fb2e0034e879264e1dc0f8f4b6af0b803eea3a3b2e52037c0284293e473d44";
              finalImageTag = "0.22.0";
              sha256 = "sha256-3zdzINIuiF9jomhy9B0xqc6ohS49/WdOlJqjJXk38IQ=";
            };

            queue-worker = pullImage {
              imageName = "ghcr.io/openfaas/queue-worker";
              imageDigest = "sha256:dd69cc3d77c2e06df54ed2dddea384b6defc51ec35763a5ed377548fd30c6831";
              finalImageTag = "0.12.2";
              sha256 = "sha256-Rq5xPkEfkd0NrDcIb5YY4SfAsYlqvQxN7yXx0/01lJs=";
            };

            nats = pullImage {
              imageName = "docker.io/library/nats-streaming";
              imageDigest = "sha256:ba1be2cd913a1e9f1ffc9445e5c04c169db333819beb7204deb3bc7c29fde5a8";
              finalImageTag = "0.22.0";
              sha256 = "sha256-hUY3GAyAveHnpxHmlX9jkKQG8vzgJfuEqeNZB4bByqU=";
            };

            prometheus = pullImage {
              imageName = "docker.io/prom/prometheus";
              imageDigest = "sha256:907e20b3b0f8b0a76a33c088fe9827e8edc180e874bd2173c27089eade63d8b8";
              finalImageTag = "v2.14.0";
              sha256 = "sha256-OTGGUOPgx2k2QPG+r5kj4slOXzzs3JUwvGoKWFW4BDw=";
            };
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

          basic-auth-image = pkgs.openfaas-images.basic-auth;
          gateway-image = pkgs.openfaas-images.gateway;
          queue-worker-image = pkgs.openfaas-images.queue-worker;
          nats-image = pkgs.openfaas-images.nats;
          prometheus-image = pkgs.openfaas-images.prometheus;
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
