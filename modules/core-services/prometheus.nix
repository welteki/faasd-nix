{ ... }:
{
  config.services.faasd.containers = {
    prometheus = {
      image = "docker.io/prom/prometheus:v2.14.0";
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
