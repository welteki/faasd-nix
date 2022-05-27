{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;
in
{
  config.services.faasd.containers = {
    nats = {
      image = "docker.io/library/nats-streaming:0.22.0";
      imageFile = lib.mkIf cfg.seedCoreImages pkgs.openfaas-images.nats;
      command = [
        "/nats-streaming-server"
        "-m"
        "8222"
        "--store=file"
        "--dir=/nats"
        "--cluster_id=faas-cluster"
      ];
      volumes = [
        {
          type = "bind";
          source = "./nats";
          target = "/nats";
        }
      ];
      user = "65534";
    };
  };
}
