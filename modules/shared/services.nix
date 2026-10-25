# dots.services: things that are switched on and off by hand rather than
# running all the time (Immich, Tailscale, a game server, ...). Each entry says
# how to bring it up, take it down and check it, which gives:
#   - optionally a `<command> up|down|status` CLI (dots.services.<name>.command),
#   - the list the DMS services menu shows (modules/home/dank/services-menu.nix),
#   - on NixOS, a polkit rule letting the dots user start and stop the entry's
#     system unit without a password (modules/nixos/services.nix).
# Imported by both the NixOS and the home-manager module sets: NixOS entries
# are system-wide, home-manager entries belong to the user (e.g. a user unit).
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkDefault types;
  systemctl = "${pkgs.systemd}/bin/systemctl";

  service = types.submodule ({
    name,
    config,
    ...
  }: {
    options = {
      label = mkOption {
        type = types.str;
        default = name;
        description = "The name the services menu shows.";
      };
      icon = mkOption {
        type = types.str;
        default = "settings";
        description = "A Material Symbols icon name for the services menu.";
      };
      unit = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "immich.target";
        description = ''
          A systemd unit (with its suffix) that is the service. up, down and
          status then default to starting, stopping and checking it, and on
          NixOS the dots user may start and stop it without a password.
        '';
      };
      userUnit = mkOption {
        type = types.bool;
        default = false;
        description = "Whether unit is a user unit (systemctl --user) rather than a system one.";
      };
      up = mkOption {
        type = types.listOf types.str;
        description = "The command (argv) that brings the service up.";
      };
      down = mkOption {
        type = types.listOf types.str;
        description = "The command (argv) that takes the service down.";
      };
      status = mkOption {
        type = types.listOf types.str;
        description = "The command (argv) that exits 0 while the service is up. It runs each time the services menu opens, so keep it cheap.";
      };
      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "immich";
        description = "If set, installs a `<command> up|down|status` CLI.";
      };
      fallback = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "A program the CLI hands any other arguments to, for a command whose name a real program already uses.";
      };
    };
    config = lib.mkIf (config.unit != null) (let
      ctl = [systemctl] ++ lib.optional config.userUnit "--user";
    in {
      up = mkDefault (ctl ++ ["start" config.unit]);
      down = mkDefault (ctl ++ ["stop" config.unit]);
      status = mkDefault (ctl ++ ["is-active" "--quiet" config.unit]);
    });
  });

  cli = s:
    pkgs.writeShellScriptBin s.command ''
      case "''${1:-status}" in
        up) exec ${lib.escapeShellArgs s.up} ;;
        down) exec ${lib.escapeShellArgs s.down} ;;
        status)
          if ${lib.escapeShellArgs s.status} >/dev/null 2>&1; then echo up; else echo down; exit 3; fi ;;
        *)
          ${
        if s.fallback != null
        then ''exec ${s.fallback} "$@"''
        else ''echo "usage: ${s.command} [up|down|status]" >&2; exit 2''
      } ;;
      esac
    '';
in {
  options.dots = {
    services = mkOption {
      type = types.attrsOf service;
      default = {};
      description = "Services switched on and off by hand. See the comment at the top of modules/shared/services.nix.";
    };
    servicesPackages = mkOption {
      type = types.listOf types.package;
      readOnly = true;
      internal = true;
      default = map cli (lib.filter (s: s.command != null) (lib.attrValues config.dots.services));
      description = "The CLIs for dots.services, installed by the NixOS or home-manager side.";
    };
  };
}
