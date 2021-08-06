{
  description = "A lightweight & portable faas engine";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    faasd-src = {
      url = "https://github.com/openfaas/faasd/archive/refs/tags/0.13.0.tar.gz";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, faasd-src, ... }:
    let
      faasdVersion = "0.13.0";
      faasdRev = "12ada59bf1289ea1543a56d7f711194251fb8a95";

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
            buildFlagsArray = [
              ''
                -ldflags=
                -s -w
                -X main.Version=${version}
                -X main.GitCommit=${commit}
              ''
              "-a"
            ];
          };
        in
        {
          containerd = buildGoModule rec {
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
        imports = [ ./faasd-module.nix ];
        nixpkgs.overlays = [ self.overlay ];
      };
    } // utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in
      {
        defaultPackage = pkgs.faasd;

        devShell = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
      });
}
