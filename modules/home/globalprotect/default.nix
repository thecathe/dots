# GlobalProtect VPN (a Palo Alto portal) from the command line, without the
# vendor's client: `globalprotect up | down | status`.
#
# Which package does what (all from nixpkgs):
#   gpclient  the VPN client. Builds the tunnel (it vendors OpenConnect), so it
#             must run as root. Needed.
#   gpauth    the single-sign-on helper (SAML, e.g. Microsoft Entra): opens your
#             browser and hands the login result to gpclient. Needed; gpclient
#             would call it itself under sudo, but then root has to launch a
#             browser in your Wayland session, so this module runs it as you.
#   openconnect, gp-saml-gui, networkmanager-openconnect
#             not used: the engine under gpclient, an older SAML helper for
#             plain openconnect, and a NetworkManager plugin whose SAML support
#             for GlobalProtect is unreliable.
# nixpkgs no longer has a NixOS module for GlobalProtect (services.globalprotect
# was removed), and none is needed: this is a home-manager module with no system
# part, so it works the same on NixOS, on Ubuntu with standalone home-manager,
# and in a second user's own flake (homeModules.globalprotect, or import this
# directory by path).
#
# `up` asks for your sudo password (gpclient needs root for the tunnel), opens
# the browser for the login, then stays in the foreground holding the
# connection; Ctrl-C or `globalprotect down` from another terminal ends it.
# nixpkgs has gpclient 2.6.5, which has no --background mode.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.globalprotect;

  gpclient = "${cfg.package}/bin/gpclient";
  gpauth = "${cfg.authPackage}/bin/gpauth";

  # `sudo` is deliberately not given by a runtimeInputs/PATH entry from nixpkgs:
  # that copy is not setuid and cannot work. The host's own sudo is found on PATH
  # (NixOS: /run/wrappers/bin/sudo, Ubuntu: /usr/bin/sudo). gpclient is named by
  # its store path because sudo's secure_path knows nothing of ~/.nix-profile.
  globalprotect = pkgs.writeShellScriptBin "globalprotect" ''
    portal=${lib.escapeShellArg (toString cfg.portal)}
    lock=/var/run/gpclient.lock

    # gpclient records its pid in the lock file; the process name is checked too,
    # so a stale file left by a crash does not read as "up".
    is_up() {
      local pid
      pid=$(cat "$lock" 2>/dev/null) || return 1
      [ -n "$pid" ] && grep -q gpclient "/proc/$pid/comm" 2>/dev/null
    }

    case "''${1:-status}" in
      up)
        if is_up; then echo "already up"; exit 0; fi
        # Ask for the password first, so the prompt does not appear while the
        # browser is open and sudo's cached credentials cover the pipeline below.
        sudo -v || exit
        set -o pipefail
        ${gpauth} "$portal" --browser ${lib.escapeShellArg cfg.browser} \
          | sudo ${gpclient} connect "$portal" --cookie-on-stdin ${lib.escapeShellArgs cfg.connectArgs}
        ;;
      down)
        sudo ${gpclient} disconnect --wait 2
        ;;
      status)
        if is_up; then echo up; else echo down; exit 3; fi
        ;;
      *)
        echo "usage: globalprotect [up|down|status]" >&2
        exit 2
        ;;
    esac
  '';
in {
  options.dots.globalprotect = {
    enable = lib.mkEnableOption "the globalprotect command (GlobalProtect VPN through gpclient)";

    portal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "vpn.example.com";
      description = ''
        The GlobalProtect portal to connect to (host name only). Required when
        enabled: it names an organisation, so dots does not default it.
      '';
    };

    browser = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      example = "firefox";
      description = ''
        The browser gpauth opens for the login: `auto` (Chrome, then Firefox,
        then the system default), `default` (the system default) or a browser
        name.
      '';
    };

    connectArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--gateway" "gateway.example.com"];
      description = ''
        Extra arguments for `gpclient connect`, e.g. a fixed gateway (otherwise
        gpclient asks) or `--hip` for portals that require a host-integrity report.
      '';
    };

    package = lib.mkPackageOption pkgs "gpclient" {};
    authPackage = lib.mkPackageOption pkgs "gpauth" {};
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.portal != null && cfg.portal != "";
        message = "dots.globalprotect.portal must be set when dots.globalprotect.enable is true";
      }
    ];

    home.packages = [globalprotect];
  };
}
