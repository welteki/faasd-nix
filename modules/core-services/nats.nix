{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;

  nats = pullImage {
    imageName = "docker.io/library/nats-streaming";
    imageDigest = "sha256:ba1be2cd913a1e9f1ffc9445e5c04c169db333819beb7204deb3bc7c29fde5a8";
    finalImageTag = "0.22.0";
    sha256 = "sha256-hUY3GAyAveHnpxHmlX9jkKQG8vzgJfuEqeNZB4bByqU=";
  };
in
{
  config.services.faasd.containers = {
    nats = {
      image = "docker.io/library/nats-streaming:0.22.0";
      imageFile = lib.mkIf cfg.seedCoreImages nats;
      command = [
        "/nats-streaming-server"
        "-m"
        "8222"
        "--store=memory"
        "--cluster_id=faas-cluster"
      ];
    };
  };
}
