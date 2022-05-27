{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;

  basic-auth-plugin = pullImage {
    imageName = "ghcr.io/openfaas/basic-auth";
    imageDigest = "sha256:e99c385f248ce9a6569bf262e3480ddbf317cd5982243fcc229ee1766d24eb5a";
    finalImageTag = "0.21.4";
    sha256 = "sha256-LyXZcK7bmc1B/QNdgvfNiL5t/5IpvnLKtFokBxRIMa4=";
  };
in
{
  config.services.faasd.containers = lib.mkIf cfg.basicAuth.enable {
    basic-auth-plugin = {
      image = "ghcr.io/openfaas/basic-auth:0.21.0";
      imageFile = lib.mkIf cfg.seedCoreImages basic-auth-plugin;
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
