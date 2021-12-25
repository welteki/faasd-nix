{ ... }:
{
  config.services.faasd.containers = {
    nats = {
      image = "docker.io/library/nats-streaming:0.22.0";
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
