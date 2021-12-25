{ ... }:
{
  config.services.faasd.containers = {
    queue-worker = {
      image = "ghcr.io/openfaas/queue-worker:0.12.2";
      environment = {
        faas_nats_address = "nats";
        faas_nats_port = 4222;
        gateway_invoke = "true";
        faas_gateway_address = "gateway";
        ack_wait = "5m5s";
        max_inflight = 1;
        write_debug = "false";
        basic_auth = "true";
        secret_mount_path = "/run/secrets";
      };
      volumes = [
        {
          type = "bind";
          source = "./secrets/basic-auth-password";
          target = "/run/secrets/basic-auth-password";
        }
        {
          type = "bind";
          source = "./secrets/basic-auth-user";
          target = "/run/secrets/basic-auth-user";
        }
      ];
      cap_add = [ "CAP_NET_RAW" ];
      depends_on = [
        "nats"
      ];
    };
  };
}
