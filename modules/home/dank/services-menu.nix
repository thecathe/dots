# The DMS "Services" bar menu (plugins/dotsServices): every dots.services
# entry on this machine, the system-wide ones (NixOS, through osConfig) and the
# user's own (home-manager), with whether each is up and a click to switch it.
# Statuses are checked only when the menu opens, by one generated script. A
# service with `actions` also gets a "..." button on its row listing them, and
# one with a `detail` shows that word on its row while it is up.
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

  # What an up service prints: "<name> up", with " <word>" after it when it has
  # a `detail` command that printed one. The word is cut down to the first line
  # and to letters, digits, _ and -, because the menu splits the line on spaces;
  # the command gets two seconds, so it cannot hold the menu up.
  upLine = name: s:
    if s.detail == null
    then "echo ${lib.escapeShellArg "${name} up"}"
    else ''
      detail=$(${pkgs.coreutils}/bin/timeout 2 ${lib.escapeShellArgs s.detail} 2>/dev/null | ${pkgs.coreutils}/bin/head -n 1 | ${pkgs.coreutils}/bin/tr -cd 'A-Za-z0-9_-')
      echo ${lib.escapeShellArg "${name} up"}"''${detail:+ $detail}"
    '';

  # One line per service: "<name> up" (see above) or "<name> down".
  statusScript = pkgs.writeShellScript "dots-services-status" (lib.concatStrings (lib.mapAttrsToList (name: s: ''
      if ${lib.escapeShellArgs s.status} >/dev/null 2>&1; then
        ${upLine name s}
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
              inherit (a) label icon requiresUp;
              argv = actionArgv "${s.label}: ${a.label}" a;
            })
            s.actions;
        })
        services;
      statusCommand = "${statusScript}";
    };
  };
}
