<!-- markdownlint-disable no-inline-html -->
<div align="center">
  <h1 id="header" >
    <!-- markdownlint-disable line-length -->
    <br>
    <ruby>
      <rp>(</rp><rt>nixdg-ninja</rt><rp>)</rp>
    </ruby>
  </h1>
  <p>
    NixOS module that enforces XDG Base Directory Specification compliance for
    common development tools and programs.
  </p>
</div>

## Overview

[XDG Base Directory Specification]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
[xdg-ninja]: https://github.com/b3nj5m1n/xdg-ninja

`nixdg-ninja`, named after the super-helpful [xdg-ninja] is a utility to help
you maintain a _reasonably clean_[^1] home directory by automatically
configuring programs to follow the[XDG Base Directory Specification]. Instead of
cluttering your `$HOME` with configuration files and data directories, this
module redirects programs to use appropriate XDG directories like `~/.config`,
`~/.cache`, `~/.local/share`, and `~/.local/state` by setting relevant XDG-spec
related variables and at times configuration files.

[^1]: Some programs simply refuse to put their state anywhere other than `~` and
    others, while they _technically_ support the state, misbehave if you move
    the state.

## Motivation

I hate garbage in my `$HOME`. I _hate_ it. Over years I've accumulated a
collection of variables that tell certain programs where their state must go
with varying success. Without this, as many programs _still_ don't follow XDG
standards out of the box, we get:

- A cluttered home directory with dotfiles scattered everywhere
- Inconsistent configuration and data storage locations
- Difficulty in backing up or managing program-specific data
- Poor organization of temporary files and caches

This module system hopes to solve these issues a declarative, shared way to
configure XDG compliance for multiple programs at once, with sensible defaults
that can be customized as needed.

## Features

[Hjem]: https://github.com/feel-co/hjem

Those describe the core tenants of my design principles rather than a generic
features section. Here is a possibly-outdated list of what nixdg-ninja can do.

- Define XDG compliance settings in your NixOS configuration, with support for
  [Hjem] and similar tools in the future.
- Pre-configured support for popular development tools
- Automatically sets up XDG-compliant environment variables
- Creates necessary configuration files in appropriate locations
- Enable/disable compliance for individual programs
- Easy to add support for additional programs

## Installation

### Using Flakes

Add this flake to your NixOS configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixdg-ninja.url = "github:notashelf/nixdg-ninja";
  };

  outputs = { self, nixpkgs, nixdg-ninja, ... }: {
    nixosConfigurations.yourhost = nixpkgs.lib.nixosSystem {
      modules = [
        nixdg-ninja.nixosModules.nixdg-ninja
        ./configuration.nix
      ];
    };
  };
}
```

## Usage

### Basic Configuration

Enable the module in your NixOS configuration:

```nix
{
  programs.nixdg-ninja = {
    enable = true;
  };
}
```

This will enable XDG compliance for all supported programs with their default
configurations.

### Selective Program Configuration

You can enable or disable specific programs:

```nix
{
  programs.nixdg-ninja = {
    enable = true;
    programs = {
      # Enable Java ecosystem XDG compliance
      java.enable = true;

      # Disable npm XDG compliance
      npm.enable = false;

      # Keep other programs at their defaults
    };
  };
}
```

### Custom Environment Variables

Override or extend environment variables for specific programs:

```nix
{
  programs.nixdg-ninja = {
    enable = true;
    programs = {
      go = {
        enable = true;
        variables = {
          GOPATH = "$XDG_DATA_HOME/go";
          GOCACHE = "$XDG_CACHE_HOME/go-build";
        };
      };
    };
  };
}
```

### Custom Configuration Files

Add or modify configuration files for programs:

```nix
{
  programs.nixdg-ninja = {
    enable = true;
    programs = {
      npm = {
        enable = true;
        files."npmrc" = {
          target = "npmrc";
          text = ''
            prefix=$XDG_DATA_HOME/npm
            cache=$XDG_CACHE_HOME/npm
            registry=https://your-custom-registry.com
          '';
        };
      };
    };
  };
}
```

## XDG Directory Structure

When enabled, this module sets up the following XDG environment variables:

- `XDG_CONFIG_HOME`: `$HOME/.config` - User-specific configuration files
- `XDG_CACHE_HOME`: `$HOME/.cache` - User-specific cache files
- `XDG_DATA_HOME`: `$HOME/.local/share` - User-specific data files
- `XDG_STATE_HOME`: `$HOME/.local/state` - User-specific state files
- `XDG_BIN_HOME`: `$HOME/.local/bin` - User-specific executables

## Contributing

Contributions are welcome! To add support for a new program:

1. Fork this repository
2. Add the program configuration to the `programs` default in `options.nix`
3. Include appropriate environment variables and configuration files
4. Test your changes, preferably in a VM test or a live configuration
5. Submit a pull request

### Adding a New Program

Here's an example of adding support for a hypothetical program:

```nix
{
  newprogram = {
    variables = {
      NEWPROGRAM_CONFIG_DIR = "$XDG_CONFIG_HOME/newprogram";
      NEWPROGRAM_DATA_DIR = "$XDG_DATA_HOME/newprogram";
    };

    # Writes to /etc/newprogram/config.txt
    files."newprogram-config" = {
      target = "newprogram/config.txt";
      text = ''
        # XDG-compliant configuration
        data_dir = $XDG_DATA_HOME/newprogram
        cache_dir = $XDG_CACHE_HOME/newprogram
      '';
    };
  };
}
```

## License

This project is licensed under the MIT License. See the LICENSE file for
details.

## Acknowledgments

- Inspired by the [XDG Base Directory Specification] and the super-awesome
  [xdg-ninja] tool.
- Built for the [NixOS](https://nixos.org/) ecosystem
- Motivated by the desire for cleaner, more organized development environments
