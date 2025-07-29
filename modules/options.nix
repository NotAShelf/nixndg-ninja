{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) nullOr submodule attrsOf str lines path oneOf listOf int;

  cfg = config.programs.nixdg-ninja;

  fileType = submodule ({
    name,
    target,
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

      target = mkOption {
        type = str;
        default = name;
        defaultText = "name";
        description = "Target path relative to either {file}`/etc` or {env}`$HOME`";
      };

      text = mkOption {
        default = null;
        type = nullOr lines;
        description = "Text of the file";
      };
    };
  });

  programType = submodule ({
    name,
    config,
    options,
    ...
  }: {
    options = {
      enable =
        mkEnableOption "XDG compliance management for this program"
        // {
          default = true;
          example = false;
        };

      variables = mkOption {
        type = attrsOf (oneOf [(listOf (oneOf [int str path])) int str path]);
        default = {};
        description = "XDG-spec compliant variables associated with a given program";
      };

      files = mkOption {
        type = attrsOf fileType;
        default = {};
        description = "Files to be associated with a given program";
      };

      # Internal
      name = mkOption {
        readOnly = true;
        type = str;
        default = name;
        description = "Name of this program";
      };
    };

    config = {};
  });
in {
  options.programs.nixdg-ninja = {
    enable = mkEnableOption "nixdg-ninja";

    programs = mkOption {
      type = attrsOf programType;
      description = "Submodule containing each program supported by nixdg-ninja.";
      default = {
        android.variables = {
          ANDROID_HOME = "$XDG_DATA_HOME/android";
          ANDROID_USER_HOME = "$XDG_DATA_HOME/android";
        };

        java.variables = {
          _JAVA_OPTIONS = "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java";
        };

        npm = {
          variables = {
            NPM_CONFIG_CACHE = "$XDG_CACHE_HOME/npm";
            NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
            NPM_CONFIG_USERCONFIG = "$XDG_CONFIG_HOME/npm/config";
          };

          files."npmrc" = {
            target = "npm/npmrc";
            text = ''
              prefix=$XDG_DATA_HOME}/npm
              cache=$XDG_CACHE_HOME}/npm
              init-module=$XDG_CONFIG_HOME/npm/config/npm-init.js
            '';
          };
        };
      };
    };

    templates = mkOption {
      readOnly = true;
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

    env = let
      filteredVars = lib.filterAttrs (_: v: (v.enable && v.variables != {})) cfg.programs;

      # Combine all enabled variables into a single attrset
      mergedVars =
        lib.foldlAttrs (
          acc: pname: pval:
            acc // pval.variables
        ) {}
        filteredVars;
    in {
      globalVars = mkOption {
        readOnly = true;
        type = attrsOf str;
        default = mergedVars;
        description = "Variables that need to be set globally in a system";
      };
    };
  };
}
