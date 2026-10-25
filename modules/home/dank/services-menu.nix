# The DMS "Services" bar menu (plugins/dotsServices): every dots.services
# entry on this machine, the system-wide ones (NixOS, through osConfig) and the
# user's own (home-manager), with whether each is up and a click to switch it.
# Statuses are checked only when the menu opens, by one generated script.
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
        })
        services;
      statusCommand = "${statusScript}";
    };
  };
}
