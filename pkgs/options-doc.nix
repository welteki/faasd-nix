{ lib, nixosOptionsDoc, runCommand, pkgs, ... }:
let
  eval = lib.evalModules {
    modules = [
      ../modules/faasd-module.nix
      ({ ... }: {
        _module.check = false;
      })
    ];
    specialArgs = { inherit pkgs; };
  };

  optionsDoc = nixosOptionsDoc {
    inherit (eval) options;
  };
in
runCommand "options-doc.md" { } ''
  cat ${optionsDoc.optionsCommonMark} >> $out
''
