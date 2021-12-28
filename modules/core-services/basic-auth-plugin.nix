{ config, pkgs, lib, ... }:
let
  inherit (pkgs.dockerTools) pullImage;

  cfg = config.services.faasd;

  basic-auth-plugin = pullImage {
    imageName = "ghcr.io/openfaas/basic-auth";
    imageDigest = "sha256:1785bd63d9062f8e90c65cefc07c3264855e5d0541ee766044cfdd6d66ccd580";
    finalImageTag = "0.21.0";
    sha256 = "sha256-en7s+NT4ByLeiT9oSIPjVT9ireXJL+n46b3vwgteJO0=";
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
