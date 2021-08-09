{ config, lib, pkgs, ... }:

with lib;
let
  importYAML = f:
    let
      jsonFile = pkgs.runCommand "in.json"
        {
          nativeBuildInputs = [ pkgs.remarshal ];
        } ''
        yaml2json < "${f}" > "$out"
      '';
    in
    builtins.fromJSON (builtins.readFile jsonFile);

  cfg = config.services.faasd;

  coreServices = importYAML "${cfg.package}/installation/docker-compose.yaml";
  dockerComposeAttrs = {
    version = coreServices.version;
    services = cfg.containers;
  };

  dockerComposeYaml = pkgs.runCommand "docker-compose.yaml" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq 'walk( if type == "object" then with_entries(select(.value != null)) else . end)' > $out <<EOL
      ${builtins.toJSON dockerComposeAttrs}
    EOL
  '';
in
{
  imports = [ ./services.nix ];

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
    networking.firewall.trustedInterfaces = [ "openfaas0" ];

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
    };

    environment.systemPackages = with pkgs; [
      cni-plugins
    ];

    services.faasd.containers = coreServices.services;

    virtualisation.containerd.enable = true;

    systemd.tmpfiles.rules = [
      "d '/var/lib/faasd'"
      "d '/var/lib/faasd-provider'"
    ];

    systemd.services.faasd-provider = {
      description = "faasd-provider";
      after = [ "network.service" "firewall.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        MemoryLimit = "500M";
        Restart = "on-failure";
        RestartSec = "10s";
        Environment = [ "basic_auth=true" "secret_mount_path=/var/lib/faasd/secrets" ];
        ExecStart = "${cfg.package}/bin/faasd provider";
        WorkingDirectory = "/var/lib/faasd-provider";
      };
    };

    systemd.services.faasd = {
      description = "faasd";
      after = [ "faasd-provider.service" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p /opt/cni
        ln -sfn "${pkgs.cni-plugins}/bin" "/opt/cni"
        
        mkdir -p /usr/local/bin
        ln -sfn "${cfg.package}/bin/faasd" "/usr/local/bin/faasd"

        mkdir -p /var/lib/faasd/secrets
        if [ ! -e "/var/lib/faasd/secrets/basic-auth-password" ] ; then
          (head -c 12 /dev/urandom | ${pkgs.perl}/bin/shasum | cut -d' ' -f1) > /var/lib/faasd/secrets/basic-auth-password
        fi

        if [ ! -e "/var/lib/faasd/secrets/basic-auth-user" ] ; then
          echo "admin" > /var/lib/faasd/secrets/basic-auth-user
        fi

        ln -sfn "${dockerComposeYaml}" "/var/lib/faasd/docker-compose.yaml"
        ln -sfn "${cfg.package}/installation/prometheus.yml" "/var/lib/faasd/prometheus.yml"
        ln -sfn "${cfg.package}/installation/resolv.conf" "/var/lib/faasd/resolv.conf"
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
