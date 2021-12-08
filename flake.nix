{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "https://github.com/openfaas/faasd/archive/refs/tags/0.14.3.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, faasd-src, ... }:
    let
      faasdVersion = "0.14.3";
      faasdRev = "ea62c1b12dd1ae1de794e6dd260351cfbd1a6759";

      supportedSystems = [
        "x86_64-linux"
      ];
    in
    {
      overlay = final: prev:

        with final;

        let
          faasdBuild = buildGoModule rec {
            pname = "faasd-build";
            version = "${faasdVersion}";
            commit = "${faasdRev}";

            src = "${faasd-src}";

            vendorSha256 = null;

            CGO_ENABLED = 0;
            ldflags = [
              "-s"
              "-w"
              "-X main.Version=${version}"
              "-X main.GitCommit=${commit}"
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

            buildFlags = [ "VERSION=v${version}" "REVISION=${src.rev}" ];

            BUILDTAGS = lib.optionals (btrfs-progs == null) [ "no_btrfs" ];

            buildPhase = ''
              patchShebangs .
              make binaries man $buildFlags
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

        packages.faasd = pkgs.faasd;
        packages.faasd-containerd = pkgs.faasd-containerd;

        defaultPackage = self.packages.${system}.faasd;

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
      });
}
