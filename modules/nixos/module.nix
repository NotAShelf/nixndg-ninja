{
  config,
  lib,
  ...
}: let
  inherit (lib.attrsets) mapAttrs;

  cfg = config.programs.nixdg-ninja;
in {
  imports = [
    ../options.nix
  ];

  config.environment = {
    variables = cfg.env.globalVars;
    etc =
      mapAttrs (name: value: {
        "${name}".text = value;
      })
      cfg.templates;
  };
}
