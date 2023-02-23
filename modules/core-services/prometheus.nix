{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;
in
{
  config.services.faasd.containers = {
    prometheus = {
      image = "docker.io/prom/prometheus:v2.41.0";
      imageFile = lib.mkIf cfg.seedCoreImages pkgs.openfaas-images.prometheus;
      volumes = [
        {
          #Config directory
          type = "bind";
          source = "./prometheus.yml";
          target = "/etc/prometheus/prometheus.yml";
        }
        {
          type = "bind";
          source = "./prometheus";
          target = "/prometheus";
        }
      ];
      cap_add = [ "CAP_NET_RAW" ];
      ports = [
        "127.0.0.1:9090:9090"
      ];
      user = "65534";
    };
  };
}
