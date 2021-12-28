{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "https://github.com/openfaas/faasd/archive/refs/tags/0.14.4.tar.gz";
      flake = false;
    };
    nixos-shell.url = "github:welteki/nixos-shell/improve-flake-support";
    nixos-shell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, utils, faasd-src, ... }@inputs:
    let
      faasdVersion = "0.14.4";
      faasdRev = "8fbdd1a461196520de75fe35ac0b5bdda6403ac7";

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

        with final;

        let
          faasdBuild = buildGoModule {
            pname = "faasd-build";
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
          };
        in
        {
          faasd-containerd = buildGoModule rec {
            pname = "containerd";
            version = "1.5.4";

            outputs = [ "out" "man" ];

            src = fetchFromGitHub {
              owner = "containerd";
              repo = "containerd";
              rev = "v${version}";
              sha256 = "sha256-VV1cxA8tDRiPDxKV8OGu3T7sgutmyL+VPNqTeFcVjJA=";
            };

            vendorSha256 = null;

            nativeBuildInputs = [ go-md2man installShellFiles util-linux ];

            buildInputs = [ btrfs-progs ];

            BUILDTAGS = lib.optionals (btrfs-progs == null) [ "no_btrfs" ];

            buildPhase = ''
              patchShebangs .
              make binaries man "VERSION=v${version}" "REVISION=${src.rev}"
            '';

            installPhase = ''
              install -Dm555 bin/* -t $out/bin
              installManPage man/*.[1-9]
              installShellCompletion --bash contrib/autocomplete/ctr
              installShellCompletion --zsh --name _ctr contrib/autocomplete/zsh_autocomplete
            '';
          };

          containerd = final.faasd-containerd;

          faasd = stdenv.mkDerivation rec {
            inherit faasdBuild;

            pname = "faasd";
            version = "${faasdVersion}";

            faasdRuntimeDeps = [
              iptables
            ];

            buildInputs = [
              makeWrapper
            ] ++ faasdRuntimeDeps;

            unpackPhase = "true";

            installPhase = ''
              mkdir -p "$out/bin"
               makeWrapper ${faasdBuild}/bin/faasd "$out/bin/faasd" \
                --prefix PATH : ${lib.makeBinPath faasdRuntimeDeps}

              mkdir -p $out/installation
              cp ${faasd-src}/docker-compose.yaml $out/installation/docker-compose.yaml
              cp ${faasd-src}/prometheus.yml $out/installation/prometheus.yml
              cp ${faasd-src}/resolv.conf $out/installation/resolv.conf
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

        packages.faasd = pkgs.faasd;
        packages.faasd-containerd = pkgs.faasd-containerd;

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
