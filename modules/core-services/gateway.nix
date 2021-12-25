{ ... }:
{
  config.services.faasd.containers = {
    gateway = {
      image = "ghcr.io/openfaas/gateway:0.21.0";
      environment = {
        basic_auth = "true";
        functions_provider_url = "http://faasd-provider:8081/";
        direct_functions = "false";
        read_timeout = "60s";
        write_timeout = "60s";
        upstream_timeout = "65s";
        faas_nats_address = "nats";
        faas_nats_port = 4222;
        auth_proxy_url = "http://basic-auth-plugin:8080/validate";
        auth_proxy_pass_body = "false";
        secret_mount_path = "/run/secrets";
        scale_from_zero = "true";
        function_namespace = "openfaas-fn";
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
        "basic-auth-plugin"
        "nats"
        "prometheus"
      ];
      ports = [
        "8080:8080"
      ];
    };
  };
}
