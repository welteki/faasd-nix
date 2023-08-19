{ writeShellScriptBin, pkgs, ... }:

writeShellScriptBin "gen-options-doc" ''
  echo "Generating NixOS module options documentation"
  cat ${pkgs.faasd-options-doc} > OPTIONS.md
''

