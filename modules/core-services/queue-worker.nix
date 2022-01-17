{ config, lib, ... }:
let
  inherit (lib) mkOption types;

  cfg = config.services.faasd;

  boolToString = e: if e then "true" else "false";

  mkContainer =
    { natsChannel ? "faas-request"
    , maxInflight ? 1
    , writeDebug ? false
    }: {
      image = "ghcr.io/openfaas/queue-worker:0.12.2";
      environment = {
        faas_nats_address = "nats";
        faas_nats_port = 4222;
        faas_nats_channel = natsChannel;
        gateway_invoke = "true";
        faas_gateway_address = "gateway";
        ack_wait = "5m5s";
        max_inflight = maxInflight;
        write_debug = boolToString writeDebug;
        basic_auth = boolToString cfg.basicAuth.enable;
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

  defaultQueueOpts = {
    maxInflight = mkOption {
      description = "Number of messages sent to queue worker and how many functions are invoked concurrently.";
      type = types.int;
      default = 1;
    };

    writeDebug = mkOption {
      description = "Print verbose logs";
      type = types.bool;
      default = false;
    };
  };

  queueOpts = { name, ... }: {
    options = defaultQueueOpts // {
      natsChannel = mkOption {
        description = "Nats channel to use for the queue. Defaults to the queue name.";
        type = types.str;
        default = name;
      };
    };
  };
in
{
  options = {
    services.faasd.defaultQueue = defaultQueueOpts;

    services.faasd.queues = mkOption {
      description = "";
      type = types.attrsOf (types.submodule queueOpts);
      default = { };
    };
  };

  config = {
    services.faasd.containers = (lib.mapAttrs'
      (queueName: cfg: {
        name = "${queueName}-worker";
        value = mkContainer cfg;
      })
      cfg.queues) // { queue-worker = mkContainer cfg.defaultQueue; };
  };
}
