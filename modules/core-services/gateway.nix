{ config, pkgs, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  inherit (types) bool int;
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;

  boolToString = e: if e then "true" else "false";

  gateway = pullImage {
    imageName = "ghcr.io/openfaas/gateway";
    imageDigest = "sha256:538cca5c2e569856dd21d348a9d265c5e55a8de12ff8d023f2940d8dab606be6";
    finalImageTag = "0.21.4";
    sha256 = "sha256-UqsI+uj2077n/XiE1BZpzccoKmMiu2g2F22E6G7ue2M=";
  };

  gatewayOpts = {
    writeTimeout = mkOption {
      description = "HTTP timeout for writing a response body from your function (in seconds)";
      type = int;
      default = 60;
    };

    readTimeout = mkOption {
      description = "HTTP timeout for reading the payload from the client caller (in seconds).";
      type = int;
      default = 60;
    };

    upstreamTimeout = mkOption {
      description = "Maximum duration of HTTP call to upstream URL (in seconds).";
      type = int;
      default = 65;
    };

    scaleFormZero = mkOption {
      description = "Enables an intercepting proxy which will scale any function from 0 replicas to the desired amount";
      type = bool;
      default = true;
    };
  };
in
{
  options = {
    services.faasd.gateway = gatewayOpts;
  };

  config = {
    services.faasd.containers.gateway = {
      image = "ghcr.io/openfaas/gateway:0.21.0";
      imageFile = mkIf cfg.seedCoreImages gateway;
      environment = {
        basic_auth = boolToString cfg.basicAuth.enable;
        functions_provider_url = "http://faasd-provider:8081/";
        direct_functions = "false";
        read_timeout = cfg.gateway.readTimeout;
        write_timeout = cfg.gateway.writeTimeout;
        upstream_timeout = cfg.gateway.upstreamTimeout;
        faas_nats_address = "nats";
        faas_nats_port = 4222;
        auth_proxy_url = "http://basic-auth-plugin:8080/validate";
        auth_proxy_pass_body = "false";
        secret_mount_path = "/run/secrets";
        scale_from_zero = boolToString cfg.gateway.scaleFormZero;
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
        "nats"
        "prometheus"
      ] ++ lib.optionals cfg.basicAuth.enable [ "basic-auth-plugin" ];
      ports = [
        "8080:8080"
      ];
    };
  };
}
