{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.faasd;

  coreServices = builtins.fromJson "${cfg.package}/faasd-installation/docker-compose.yaml";
in
{
  options.services.faasd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Lightweight faas engine";
    };

    package = mkOption {
      description = "Faasd package to use.";
      type = types.package;
      default = pkgs.faasd;
    };
  };

  config = mkIf cfg.enable {
    systemd.enableUnifiedCgroupHierarchy = false;
    
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
    };

    environment.systemPackages = with pkgs; [
      cni-plugins
    ];

    virtualisation.containerd.enable = true;

    systemd.services.faasd-provider = {
      description = "faasd-provider";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        MemoryLimit = "500M";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [ "basic_auth=true" "secret_mount_path=/var/lib/faasd/secrets" ];
        ExecStart = "${cfg.package}/bin/faasd provider";
        WorkingDirectory = "/var/lib/faasd";
      };
    };

    systemd.services.faasd = {
      description = "faasd";
      after = [ "faasd-provider.service" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        ln -sfn "${cfg.package}/bin/faasd" "/usr/local/bin/faasd"
        ln -sfn "${pkgs.cni-plugins}/bin" "/opt/cni"
        ln -sfn "${cfg.package}/installation/docker-compose.yaml" "/var/lib/faasd/docker-compose.yaml"
        ln -sfn "${cfg.package}/installation/prometheus.yml" "/var/lib/faasd/prometheus.yml"
      '';

      serviceConfig = {
        MemoryLimit = "500M";
        Restart = "on-failure";
        RestartSec = "10s";
        ExecStart = "${cfg.package}/bin/faasd up";
        WorkingDirectory = "/var/lib/faasd";
      };
    };
  };
}
