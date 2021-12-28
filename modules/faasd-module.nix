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

    basicAuth = {
      user = mkOption {
        type = types.str;
        default = "admin";
        description = "Basic-auth user";
      };
      passwordFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to file containing password";
        example = "/etc/nixos/faasd-basic-aurh-password";
      };
    };

    namespaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Openfaas function namespaces.
        Namespaces listed here will be created of they do not exist and labeled
        with `openfaas=true`.
      '';
      example = [ "dev" ];
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      networking.firewall.trustedInterfaces = [ "openfaas0" ];

      boot.kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = 1;
      };

      services.faasd.containers = coreServices.services;

      virtualisation.containerd.enable = true;

      systemd.tmpfiles.rules = [
        "d /opt/cni/bin 0755 root root -"
        "d /usr/local/bin 0755 root root -"
        "d '/var/lib/faasd'"
        "d '/var/lib/faasd-provider'"
      ];

      systemd.services.faasd-init = {
        script = ''
          # Link cni-plugins
          ln -fs ${pkgs.cni-plugins}/bin/* /opt/cni/bin

          # Link faasd binary
          ln -fs "${cfg.package}/bin/faasd" "/usr/local/bin/faasd"

          # Set basic-auth user and password
          mkdir -p /var/lib/faasd/secrets
          ${if cfg.basicAuth.passwordFile != null then
            ''ln -fs ${cfg.basicAuth.passwordFile} /var/lib/faasd/secrets/basic-auth-password''
          else
            ''
              if [ ! -e "/var/lib/faasd/secrets/basic-auth-password" ] ; then
                (head -c 12 /dev/urandom | ${pkgs.perl}/bin/shasum | cut -d' ' -f1) > /var/lib/faasd/secrets/basic-auth-password
              fi
            ''
          }
          echo ${cfg.basicAuth.user} > /var/lib/faasd/secrets/basic-auth-user

          ln -fs "${cfg.package}/installation/prometheus.yml" "/var/lib/faasd/prometheus.yml"
          ln -fs "${cfg.package}/installation/resolv.conf" "/var/lib/faasd/resolv.conf"
        '';

        before = [ "faasd-provider.service" "faasd.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
        };
      };

      systemd.services.faasd-provider = {
        description = "faasd-provider";
        after = [ "network.service" "firewall.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iptables ];

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
        path = [ pkgs.iptables ];

        preStart = ''
          ln -fs "${dockerComposeYaml}" "/var/lib/faasd/docker-compose.yaml"
        '';

        serviceConfig = {
          MemoryLimit = "500M";
          ExecStart = "${cfg.package}/bin/faasd up";
          Restart = "on-failure";
          RestartSec = "10s";
          WorkingDirectory = "/var/lib/faasd";
        };
      };
    })

    (mkIf (cfg.namespaces != [ ]) {
      systemd.services.faasd-create-namespaces = {
        description = "Create OpenFaaS namespaces";
        script = ''
          ${concatMapStrings (namespace: ''
            echo "Creating namespace ${namespace}"
            ${pkgs.containerd}/bin/ctr namespace create ${namespace} || true
            ${pkgs.containerd}/bin/ctr namespace label ${namespace} openfaas=true
          '') cfg.namespaces}
        '';

        before = [ "faasd.service" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "containerd.service" ];
        requires = [ "containerd.service" ];

        serviceConfig = {
          Type = "oneshot";
        };
      };
    })
  ];
}
