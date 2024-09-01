{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption mkIf mkMerge types concatMapStrings;
  inherit (types) package bool str attrsOf listOf enum submodule nullOr;

  cfg = config.services.faasd;

  boolToString = e: if e then "true" else "false";

  service = import ./service.nix;

  dockerComposeAttrs = {
    version = "3.7";
    services = lib.mapAttrs (k: c: c.out) cfg.containers;
  };

  dockerComposeYaml = pkgs.writeText "docker-compose.yaml" (builtins.toJSON dockerComposeAttrs);

  seedOpts = {
    options = {
      namespace = mkOption {
        description = "Namespace to use when seeding image.";
        type = str;
        default = "openfaas";
      };

      imageFile = mkOption {
        description = "Path to the image file.";
        type = package;
      };
    };
  };
in
{
  imports = import ./core-services;

  options.services.faasd = {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Lightweight faas engine";
    };

    package = mkOption {
      description = "Faasd package to use.";
      type = package;
      default = pkgs.faasd;
    };

    dockerComposeFile = mkOption {
      description = ''
        Path to docker-compose.yaml.

        By setting this all options related to faasd services will be ignored and the docker-compose configuration will be used instead.
      '';
      type = nullOr str;
      default = null;
    };

    basicAuth = {
      enable = mkOption {
        description = "Enable basicAuth";
        type = bool;
        default = true;
      };
      user = mkOption {
        type = str;
        default = "admin";
        description = "Basic-auth user";
      };
      passwordFile = mkOption {
        type = nullOr str;
        default = null;
        description = "Path to file containing password";
        example = "/etc/nixos/faasd-basic-auth-password";
      };
    };

    containers = mkOption {
      default = { };
      type = attrsOf (submodule service);
      description = "OCI (Docker) containers to run as additional services on faasd.";
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

    seedCoreImages = mkOption {
      description = "Seed faasd core images";
      type = bool;
      default = false;
    };

    seedDockerImages = mkOption {
      description = "List of docker images to preload on system";
      default = [ ];
      type = listOf (submodule seedOpts);
    };

    pullPolicy = mkOption {
      description = ''
        Set to "Always" to force a pull of images upon deployment, or "IfNotPresent" to try to use a cached image.
      '';
      type = enum [ "Always" "IfNotPresent" ];
      default = "Always";
    };

    nameserver = mkOption {
      description = "Nameserver to use";
      type = str;
      default = "8.8.8.8";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      networking.firewall.trustedInterfaces = [ "openfaas0" ];

      boot.kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = 1;
      };

      virtualisation.containerd.enable = true;

      # Seed images for containers that have imageFile attribute
      services.faasd.seedDockerImages = lib.concatMap (image: [{ imageFile = image; }])
        (lib.remove null (lib.catAttrs "imageFile" (lib.attrValues cfg.containers)));

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
          echo "nameserver ${cfg.nameserver}" > "/var/lib/faasd/resolv.conf"
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
          Environment = [ "basic_auth=${boolToString cfg.basicAuth.enable}" "secret_mount_path=/var/lib/faasd/secrets" ];
          ExecStart = "${cfg.package}/bin/faasd provider --pull-policy ${cfg.pullPolicy}";
          WorkingDirectory = "/var/lib/faasd-provider";
        };
      };

      systemd.services.faasd = {
        description = "faasd";
        after = [ "faasd-provider.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.iptables ];

        preStart = ''
          ${if (cfg.dockerComposeFile != null ) then 
            ''ln -fs ${cfg.dockerComposeFile} /var/lib/faasd/docker-compose.yaml''
          else
            ''ln -fs ${dockerComposeYaml} /var/lib/faasd/docker-compose.yaml''
          }
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

    (mkIf (cfg.seedDockerImages != [ ]) {
      systemd.services.faasd-seed-images = {
        description = "Seed faasd container images";
        script = ''
          # Seed container images
          ${concatMapStrings (opts: ''
            echo "Seeding container image: ${opts.imageFile}"
            ${if (lib.hasSuffix "gz" opts.imageFile) then
              ''${pkgs.gzip}/bin/zcat "${opts.imageFile}" | ${pkgs.containerd}/bin/ctr -n ${opts.namespace} image import -''
            else
              ''${pkgs.coreutils}/bin/cat "${opts.imageFile}" | ${pkgs.containerd}/bin/ctr -n ${opts.namespace} image import -''
            }
          '') cfg.seedDockerImages}
        '';

        before = [ "faasd.service" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "containerd.service" ];

        serviceConfig = {
          Type = "oneshot";
        };
      };
    })
  ];
}
