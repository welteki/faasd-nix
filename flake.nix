{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "github:openfaas/faasd?ref=0.16.7";
      flake = false;
    };
    nixos-shell.url = "github:Mic92/nixos-shell";
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

          environment.systemPackages = [ pkgs.faas-cli ];
          system.stateVersion = "22.05";
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
            version = "1.6.8";

            src = fetchFromGitHub {
              owner = "containerd";
              repo = "containerd";
              rev = "v${version}";
              sha256 = "sha256-l/9jOvZ4nn/wy+XPRoT1lojfGvPEXhPz2FJjLpZ/EE8=";
            };
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
              imageDigest = "sha256:43715369a226b4fb32ba37c7ebc67d79db943581a92a02ed198846c62090a023";
              finalImageTag = "0.25.2";
              sha256 = "sha256-THPqoviRmPFq1VBAk9RGSUXREbolVHOPEEJDfaXjS+o=";
            };

            gateway = pullImage {
              imageName = "ghcr.io/openfaas/gateway";
              imageDigest = "sha256:f9ecfab4c9aefe0185b755edb142710fdc037809c1cad19e2d569d638503ccc7";
              finalImageTag = "0.25.2";
              sha256 = "sha256-ByJedI/oJVVh6PjF2B07Ptiyjbcuzcq9dx7N4PsStDM=";
            };

            queue-worker = pullImage {
              imageName = "ghcr.io/openfaas/queue-worker";
              imageDigest = "sha256:a0cfce6ca30c02f2f5f11ec12e978c33e5cbe10019cce10b4a8b38404eee3913";
              finalImageTag = "0.13.1";
              sha256 = "sha256-A8yX0FqMXpwilA+DrUbPt9PuMGM/KCnN50rm4IexFwk=";
            };

            nats = pullImage {
              imageName = "docker.io/library/nats-streaming";
              imageDigest = "sha256:87746b2f927452b109461f56e64e379041225cd9c1835458ea1a629343d8b2d3";
              finalImageTag = "0.24.6";
              sha256 = "sha256-N8DHpzxOIWkAxHSnIoAG0XPuPJ5RfLLVPJOd82yeY0Q=";
            };

            prometheus = pullImage {
              imageName = "docker.io/prom/prometheus";
              imageDigest = "sha256:f2d994f9a7aae94636d4d3b0aca504f420488f70da7b0acef433eb0bf2fd71ef";
              finalImageTag = "v2.38.0";
              sha256 = "sha256-ZQ4ftIPYZ87itHP6LluEfJyvCdCYFP5AJaCf93ZolY4=";
            };
          };
        };

      nixosModules.faasd = {
        imports = [ ./modules/faasd-module.nix ];
        nixpkgs.overlays = [ self.overlay ];
      };

      nixosConfigurations.faasd-vm = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.nixos-shell.nixosModules.nixos-shell
          faasdServer
          (args: { nixos-shell.mounts.mountHome = false; })
        ];
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
            pkgs.nixos-shell
            pkgs.faas-cli
          ];
        };

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixos-shell
            pkgs.faas-cli

            pkgs.nixpkgs-fmt
          ];
        };
      });
}
