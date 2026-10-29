# The DMS "Services" bar menu (plugins/dotsServices): every dots.services
# entry on this machine, the system-wide ones (NixOS, through osConfig) and the
# user's own (home-manager), with whether each is up and a click to switch it.
# Statuses are checked only when the menu opens, by one generated script. A
# service with `actions` also gets a "..." button on its row listing them.
{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}: let
  services =
    (
      if osConfig != null
      then osConfig.dots.services or {}
      else {}
    )
    // config.dots.services;

  # One line per service: "<name> up" or "<name> down".
  statusScript = pkgs.writeShellScript "dots-services-status" (lib.concatStrings (lib.mapAttrsToList (name: s: ''
      if ${lib.escapeShellArgs s.status} >/dev/null 2>&1; then
        echo ${lib.escapeShellArg "${name} up"}
      else
        echo ${lib.escapeShellArg "${name} down"}
      fi
    '')
    services));

  # A terminal action runs in a kitty window (kitty --detach returns at once and
  # leaves the window up), through this script: it runs the command and, if that
  # failed, holds the window until Enter so the error can be read.
  terminalScript = pkgs.writeShellScript "dots-services-action" ''
    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
      echo
      read -r -p "''${1##*/} failed (exit $status). Press Enter to close. "
    fi
  '';

  actionArgv = title: a:
    if a.terminal
    then
      [
        "${config.programs.kitty.package}/bin/kitty"
        "--detach"
        "--title"
        title
        "${terminalScript}"
      ]
      ++ a.argv
    else a.argv;
in {
  assertions = [
    {
      assertion = lib.all (n: builtins.match "[A-Za-z0-9_-]+" n != null) (lib.attrNames services);
      message = "dots.services: names must be letters, digits, _ or - (the services menu reads them back from its status script)";
    }
  ];

  programs.dank-material-shell.plugins.dotsServices = {
    enable = true;
    src = ./plugins/dotsServices;
    settings = {
      services =
        lib.mapAttrsToList (name: s: {
          inherit name;
          inherit (s) label icon up down;
          actions =
            map (a: {
              inherit (a) label icon;
              argv = actionArgv "${s.label}: ${a.label}" a;
            })
            s.actions;
        })
        services;
      statusCommand = "${statusScript}";
    };
  };
}
