{lib, ...}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) nullOr submodule attrsOf str lines path;
  programType = submodule ({
    name,
    config,
    options,
    ...
  }: {
    options = {
      enable =
        mkEnableOption "creation of this file"
        // {
          default = true;
          example = false;
        };

      extraVariables = mkOption {
        type = attrsOf str;
        default = {};
        description = "XDG-spec compliant variables associated with a given program";
      };

      extraConfig = mkOption {
        type = lines;
        default = "";
        description = "Additional configuration to append to the file source";
      };

      # Internal
      name = mkOption {
        readOnly = true;
        type = str;
        default = name;
        description = "Name of this program";
      };

      path = mkOption {
        readOnly = true;
        type = nullOr str;
        description = ''
          In the case a program requires any configuration files linked in place
          this option represents the path **relative to an XDG-compliant directory**
          such as {env}`$XDG_CONFIG_HOME` for the file to be linked.
        '';
      };

      source = mkOption {
        type = nullOr path;
        default = null;
        description = "Path of the source file or directory";
      };
    };

    config = {};
  });
in {
  options.nixdg-ninja = {
    enable = mkEnableOption "nixdg-ninja";

    programs = mkOption {
      type = attrsOf programType;
      description = "Submodule containing each program supported by nixdg-ninja.";
      default = {};
    };

    templates = mkOption {
      type = attrsOf lines;
      default = {
        pythonrc =
          # python
          ''
            import os
            import atexit
            import readline
            from pathlib import Path

            if readline.get_current_history_length() == 0:

                state_home = os.environ.get("XDG_STATE_HOME")
                if state_home is None:
                    state_home = Path.home() / ".local" / "state"
                else:
                    state_home = Path(state_home)

                history_path = state_home / "python_history"
                if history_path.is_dir():
                    raise OSError(f"'{history_path}' cannot be a directory")

                history = str(history_path)

                try:
                    readline.read_history_file(history)
                except OSError: # Non existent
                    pass

                def write_history():
                    try:
                        readline.write_history_file(history)
                    except OSError:
                        pass

                atexit.register(write_history)
          '';

        npmrc = ''
          prefix=''${XDG_DATA_HOME}/npm
          cache=''${XDG_CACHE_HOME}/npm
          init-module=''${XDG_CONFIG_HOME}/npm/config/npm-init.js
        '';
      };

      description = "Template files that can be used to link 'magic' configs in place.";
    };

    env = {
      globalVars = mkOption {
        type = attrsOf str;
        default = {};
        description = "Variables that need to be set globally in a system";
      };

      sessionVars = mkOption {
        type = attrsOf str;
        default = {};
        description = "Variables that need to be set on session login";
      };
    };
  };
}
