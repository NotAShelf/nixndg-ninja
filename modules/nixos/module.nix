{
  config,
  lib,
  ...
}: let
  cfg = config.programs.nixdg-ninja;
in {
  imports = [
    ../options.nix
  ];

  config.environment = let
    enabledPrograms = lib.filterAttrs (_: v: v.enable) cfg.programs;

    allFilesByTarget =
      lib.concatMapAttrs (
        _: prog:
          lib.mapAttrs (_: file: {inherit (file) text;})
          (lib.filterAttrs (_: file: file.enable && file.text != null) prog.files)
      )
      enabledPrograms;
  in {
    # Set up global variables from collected variables
    variables = cfg.env.globalVars;

    # Link files associated with enabled programs
    etc = allFilesByTarget;
  };
}
