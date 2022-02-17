{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;

  prometheus = pullImage {
    imageName = "docker.io/prom/prometheus";
    imageDigest = "sha256:907e20b3b0f8b0a76a33c088fe9827e8edc180e874bd2173c27089eade63d8b8";
    finalImageTag = "v2.14.0";
    sha256 = "sha256-OTGGUOPgx2k2QPG+r5kj4slOXzzs3JUwvGoKWFW4BDw=";
  };
in
{
  config.services.faasd.containers = {
    prometheus = {
      image = "docker.io/prom/prometheus:v2.14.0";
      imageFile = lib.mkIf cfg.seedCoreImages prometheus;
      volumes = [
        {
          #Config directory
          type = "bind";
          source = "./prometheus.yml";
          target = "/etc/prometheus/prometheus.yml";
        }
      ];
      cap_add = [ "CAP_NET_RAW" ];
      ports = [
        "127.0.0.1:9090:9090"
      ];
    };
  };
}
