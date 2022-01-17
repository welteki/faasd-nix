{ config, lib, ... }:
let
  cfg = config.services.faasd;
in
{
  config.services.faasd.containers = lib.mkIf cfg.basicAuth.enable {
    basic-auth-plugin = {
      image = "ghcr.io/openfaas/basic-auth:0.21.0";
      environment = {
        port = 8080;
        secret_mount_path = "/run/secrets";
        user_filename = "basic-auth-user";
        pass_filename = "basic-auth-password";
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
    };
  };
}
