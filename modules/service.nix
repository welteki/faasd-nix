{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types optionalAttrs;
  inherit (types) listOf nullOr attrsOf str either int bool submodule;

  link = url: text:
    ''link:${url}[${text}]'';
  dockerComposeRef = fragment:
    ''See ${link "https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#${fragment}" "Compose Specification#${fragment}"}'';
in
{
  options = {
    out = mkOption {
      type = attrsOf types.unspecified;
      readOnly = true;
    };

    image = mkOption {
      type = str;
      description = dockerComposeRef "image";
    };

    depends_on = mkOption {
      type = listOf str;
      default = [ ];
      description = dockerComposeRef "depends_on";
    };

    environment = mkOption {
      type = either (attrsOf (either str int)) (listOf str);
      default = { };
      description = dockerComposeRef "environment";
    };

    volumes = mkOption {
      type = listOf types.unspecified;
      default = [ ];
      description = dockerComposeRef "volumes";
    };

    ports = mkOption {
      type = listOf types.unspecified;
      default = [ ];
      description = dockerComposeRef "ports";
    };

    user = mkOption {
      type = nullOr str;
      default = null;
      description = dockerComposeRef "user";
    };

    command = mkOption {
      type = nullOr types.unspecified;
      default = null;
      description = dockerComposeRef "command";
    };

    cap_add = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "CAP_NET_RAW" "SYS_ADMIN" ];
      description = dockerComposeRef "cap_add";
    };

    entrypoint = mkOption {
      type = nullOr str;
      default = null;
      description = dockerComposeRef "entypoint";
    };
  };

  config.out = {
    inherit (config) image;
  } // optionalAttrs (config.depends_on != [ ]) {
    inherit (config) depends_on;
  } // optionalAttrs (config.environment != [ ] || config.environment != { }) {
    inherit (config) environment;
  } // optionalAttrs (config.volumes != [ ]) {
    inherit (config) volumes;
  } // optionalAttrs (config.ports != [ ]) {
    inherit (config) ports;
  } // optionalAttrs (config.user != null) {
    inherit (config) user;
  } // optionalAttrs (config.command != null) {
    inherit (config) command;
  } // optionalAttrs (config.cap_add != [ ]) {
    inherit (config) cap_add;
  } // optionalAttrs (config.entrypoint != null) {
    inherit (config) entrypoint;
  };
}
