# dots.servicesCli: the `services` command over dots.services (see
# modules/shared/services.nix). It lists every entry on this machine, the
# system-wide ones (NixOS, read through osConfig) and the user's own, says which
# are up, brings one up or down, and runs an entry's extra actions, in the
# terminal you are in. services.sh is the program; this module builds the file
# of entries it reads and installs it. The DMS services menu shows the same
# entries (dank/services-menu.nix).
{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}: let
  cfg = config.dots.servicesCli;

  services =
    (
      if osConfig != null
      then osConfig.dots.services or {}
      else {}
    )
    // config.dots.services;

  # A terminal action in its own window (`services action ... --window`, which
  # is what the menu asks for): kitty, in a transient scope of its own because
  # a program a DMS plugin starts lives in dms.service's cgroup, which is killed
  # whenever DMS restarts (any rebuild that changes its plugins or settings),
  # and the window would die with it. Run through `holdScript`, which keeps the
  # window open after a failure until Enter, so the error can be read.
  holdScript = pkgs.writeShellScript "dots-services-action" ''
    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
      echo
      read -r -p "''${1##*/} failed (exit $status). Press Enter to close. "
    fi
  '';

  duplicates = names: lib.unique (lib.filter (n: lib.count (m: m == n) names > 1) names);
  namesOf = x: [x.id] ++ lib.optional (x.short != null) x.short;
  serviceNames = lib.concatMap namesOf (lib.attrValues services);
in {
  # Declares dots.services, so this module also evaluates imported on its own.
  # Imported twice (with the rest of dots) it is one module.
  imports = [../../shared/services.nix];

  options.dots.servicesCli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = services != {};
      defaultText = lib.literalMD "whether this machine has any `dots.services` entry";
      description = "Install the `services` command.";
    };

    name = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9_-]+";
      default = "services";
      example = "svc";
      description = "The name of the command.";
    };

    timeout = lib.mkOption {
      type = lib.types.numbers.nonnegative;
      default = 3;
      example = 1.5;
      description = ''
        How many seconds each status check (and `detail`) may take before the
        service is reported as `unknown`; 0 for no limit. `-t` on the command
        line replaces it for one run.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = import ./package.nix {
        inherit pkgs;
        inherit (cfg) manifest;
      };
      defaultText = lib.literalMD "the command built from `dots.services` and the options above";
      description = "The `services` command.";
    };

    manifest = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      internal = true;
      default = {
        inherit (cfg) name timeout;
        window = {
          prefix = [
            "${pkgs.systemd}/bin/systemd-run"
            "--user"
            "--scope"
            "--collect"
            "--quiet"
            "${config.programs.kitty.package}/bin/kitty"
            "--detach"
          ];
          wrapper = "${holdScript}";
        };
        services =
          lib.mapAttrsToList (_: s: {
            inherit (s) id short label icon up down status detail;
            actions = map (a: {inherit (a) id short label icon argv terminal requiresUp;}) s.actions;
          })
          services;
      };
      defaultText = lib.literalMD "what `services` reads, built from `dots.services`";
      description = "The file of entries the command reads, as an attribute set (for checks).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      [
        {
          assertion = duplicates serviceNames == [];
          message = "dots.services: ids and short names must be different from each other, but these are used twice: ${lib.concatStringsSep ", " (duplicates serviceNames)}";
        }
      ]
      ++ lib.mapAttrsToList (_: s: {
        assertion = duplicates (lib.concatMap namesOf s.actions) == [];
        message = "dots.services.${s.id}.actions: ids and short names must be different from each other, but these are used twice: ${lib.concatStringsSep ", " (duplicates (lib.concatMap namesOf s.actions))}";
      })
      services;

    home.packages = [cfg.package];
  };
}
