{ config, pkgs, lib, ... }:
let
  inherit (import ../../images.nix) prometheus;

  cfg = config.services.faasd;
in
{
  config.services.faasd.containers = {
    prometheus = {
      image = "${prometheus.imageName}:${prometheus.finalImageTag}";
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
