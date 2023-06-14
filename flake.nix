{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "github:openfaas/faasd?ref=0.16.9";
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
      overlays.default = final: prev:
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
            version = "1.7.0";

            src = fetchFromGitHub {
              owner = "containerd";
              repo = "containerd";
              rev = "v${version}";
              sha256 = "sha256-OHgakSNqIbXYDC7cTw2fy0HlElQMilDbSD5SSjbYJhc=";
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

            subPackages = [
              "plugins/ipam/dhcp"
              "plugins/ipam/host-local"
              "plugins/ipam/static"
              "plugins/main/bridge"
              "plugins/main/host-device"
              "plugins/main/ipvlan"
              "plugins/main/loopback"
              "plugins/main/macvlan"
              "plugins/main/ptp"
              "plugins/main/vlan"
              "plugins/meta/bandwidth"
              "plugins/meta/firewall"
              "plugins/meta/portmap"
              "plugins/meta/sbr"
              "plugins/meta/tuning"
              "plugins/meta/vrf"
            ];
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
            gateway = pullImage {
              imageName = "ghcr.io/openfaas/gateway";
              imageDigest = "sha256:9e9f1e97a9c1243ac3d92387679e55094a6cd6162fd28fff51a125bba8c5cfcc";
              finalImageTag = "0.26.3";
              sha256 = "sha256-tn5vaRHco+zdfWDOGrLkI/t8QU+7cPQYQuRX/pvsexI=";
            };

            queue-worker = pullImage {
              imageName = "ghcr.io/openfaas/queue-worker";
              imageDigest = "sha256:50ba67a2d12b211975871871a5fb775c41a6123d96b2167941bfb70a8001781c";
              finalImageTag = "0.13.3";
              sha256 = "sha256-Aiw6eF2koBesafjPXiDBNjjNLYoOxxGXK9ScQW1mVDw=";
            };

            nats = pullImage {
              imageName = "docker.io/library/nats-streaming";
              imageDigest = "sha256:1a8745712d00a54265c8552863b8d15a568b138368f4fcb090c075e361124c14";
              finalImageTag = "0.25.3";
              sha256 = "sha256-0TCAWZ2qwLlbTN+IE8BxvfYVqwnc6waTWjwbbMg6CwE=";
            };

            prometheus = pullImage {
              imageName = "docker.io/prom/prometheus";
              imageDigest = "sha256:01d64f9e6638cf8d6f9cc3c4defa080431e8c726d73dc3997e218efee4ee1b78";
              finalImageTag = "v2.41.0";
              sha256 = "sha256-/E9iCIl2n2Wv1KSsyblQy57I2H8v7tmP3zim5taatr0=";
            };
          };
        };

      nixosModules.faasd = {
        imports = [ ./modules/faasd-module.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };

      nixosConfigurations.faasd-vm = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.nixos-shell.nixosModules.nixos-shell
          faasdServer
          (args: { nixos-shell.mounts.mountHome = false; })
        ];
      };

      checks.x86_64-linux.faasd = with import (nixpkgs + "/nixos/lib/testing-python.nix") { system = "x86_64-linux"; };
        simpleTest {
          name = "faasd";

          nodes.faasd = { pkgs, ... }:
            let
              images = {
                figlet = pkgs.dockerTools.pullImage {
                  imageName = "ghcr.io/openfaas/figlet";
                  imageDigest = "sha256:98b7e719cabe654a7d2f8ff0f3c11294ef737a1f1e4eeef7321277420dfebe8d";
                  finalImageTag = "latest";
                  sha256 = "sha256-leYfLXQ4cCvPOudU82UaV9BkUIA+W6YvM0zx3BlyCjw=";
                };

                nodeInfo = pkgs.dockerTools.pullImage {
                  imageName = "ghcr.io/openfaas/nodeinfo";
                  imageDigest = "sha256:018db1b62c35acf63ff79be5e252128b2477c134421fe1322c159438edf6bcaf";
                  finalImageTag = "stable";
                  sha256 = "sha256-1hOPmt9fKdQUPokVhx9C62XYYC9iZ++QVI/iEb5+/Hk=";
                };
              };
            in
            {
              imports = [ faasdServer ];

              services.faasd = {
                seedCoreImages = true;
                seedDockerImages = [
                  {
                    namespace = "openfaas-fn";
                    imageFile = images.figlet;
                  }
                  {
                    namespace = "openfaas-fn";
                    imageFile = images.nodeInfo;
                  }
                ];
                pullPolicy = "IfNotPresent";
                # Use local DNS server.
                nameserver = "127.0.0.1";
              };

              # Start local DNS server. Required by faasd to function when running
              # without internet connection.
              services.coredns.enable = true;
            };
          testScript =
            ''
              # Wait until faasd can receive HTTP requests
              faasd.wait_for_job("faasd-provider")
              faasd.wait_for_job("faasd")
              faasd.wait_for_open_port(8080)

              with subtest("login to faasd"):
                faasd.succeed(
                  "cat /var/lib/faasd/secrets/basic-auth-password | faas-cli login --password-stdin")

              with subtest("deploy and invoke functions"):
                faasd.succeed("faas-cli deploy --image ghcr.io/openfaas/figlet:latest --name figlet")
                faasd.succeed("echo faasd | faas-cli invoke figlet")
                faasd.succeed("echo faasd | faas-cli invoke figlet --async")
            '';
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
          overlays = [ self.overlays.default ];
        };
      in
      {
        packages = {
          default = pkgs.faasd;
          inherit (pkgs) faasd faasd-containerd faasd-cni-plugins;

          gateway-image = pkgs.openfaas-images.gateway;
          queue-worker-image = pkgs.openfaas-images.queue-worker;
          nats-image = pkgs.openfaas-images.nats;
          prometheus-image = pkgs.openfaas-images.prometheus;

          faasd-test = self.checks.${system}.faasd;
        };

        devShells.faasd-vm = pkgs.mkShell {
          buildInputs = [
            pkgs.nixos-shell
            pkgs.faas-cli
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixos-shell
            pkgs.faas-cli

            pkgs.nixpkgs-fmt
          ];
        };
      });
}
