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

  environment = {
    variables = cfg.env.globalVars;
    sessionVariables = cfg.env.sessionVars;
    etc =
      mapAttrs (name: value: {
        "${name}".text = value;
      })
      cfg.templates;
  };
}
