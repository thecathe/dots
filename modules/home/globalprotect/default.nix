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
#
# The browser sign-in ends on a page that opens a `globalprotectcallback:` link;
# the desktop must hand that to `gpclient launch-gui`, which passes it to the
# waiting gpauth. nixpkgs' gpclient ships a desktop file that declares this, but
# only the wrapper below is installed, so the module registers the handler itself.
# Without it the page just says "Please click Open GlobalProtect" and nothing happens.
#
# It is also an entry of the DMS services menu (dots.services.globalprotect,
# next to Tailscale), shown on the hosts that enable it. The menu has no
# keyboard, so a click opens a terminal that runs `globalprotect up|down` for
# the password prompt. The entry is plain data: without the menu it does nothing.
#
# Since `up` is the connection, the window it runs in would have to stay open for
# as long as the VPN is wanted. So the menu runs `up` inside a tmux session of its
# own: closing the window only detaches, and the connection carries on. Clicking
# "up" again, or `globalprotect attach`, shows that session again. `down` ends
# gpclient, which ends the session. Plain `globalprotect up` from a shell is
# unchanged (foreground, no tmux).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dots.globalprotect;

  gpclient = "${cfg.package}/bin/gpclient";
  gpauth = "${cfg.authPackage}/bin/gpauth";

  # The menu's tmux: a server of its own (-L), so it never touches the user's
  # tmux, and no config file (-f /dev/null), so nobody's settings (mouse, prefix,
  # status bar) change how the window behaves. The server exits with its last
  # session, so each connection starts a fresh one in the current desktop
  # session's environment (the browser launch needs WAYLAND_DISPLAY).
  tmuxSession = "globalprotect";
  tmuxCmd = lib.concatStringsSep " " [
    "${pkgs.tmux}/bin/tmux"
    "-L ${tmuxSession}"
    "-f /dev/null"
  ];

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
      attach)
        # The session the services menu started `up` in. A $TMUX from the
        # caller's own tmux would make tmux refuse to nest.
        unset TMUX
        if ! ${tmuxCmd} has-session -t ${tmuxSession} 2>/dev/null; then
          echo "no GlobalProtect session: nothing was started from the services menu" >&2
          exit 1
        fi
        exec ${tmuxCmd} attach -t ${tmuxSession}
        ;;
      *)
        echo "usage: globalprotect [up|down|status|attach]" >&2
        exit 2
        ;;
    esac
  '';

  # The services menu runs a service's up or down and waits for it to exit (10 s
  # at most). `globalprotect up` needs the sudo password and runs for as long as
  # the tunnel is up, so the menu opens a terminal for it: kitty --detach returns
  # at once and leaves the window running. The window closes when the command
  # ends; if the command failed it waits for Enter, so the error can be read.
  # `wrap` is what goes between kitty and that script (nothing, or tmux).
  inTerminal = verb: wrap:
    [
      "${config.programs.kitty.package}/bin/kitty"
      "--detach"
      "--title"
      "GlobalProtect ${verb}"
    ]
    ++ wrap [
      "${pkgs.writeShellScript "globalprotect-${verb}-in-terminal" ''
        ${globalprotect}/bin/globalprotect ${verb} || {
          echo
          read -r -p "globalprotect ${verb} failed. Press Enter to close. "
        }
      ''}"
    ];

  # `up` inside the menu's tmux session: attached if it already exists (a click
  # on "up" while connecting or after closing the window), else created. With no
  # config the status bar would be on; it has nothing to say here.
  inTmux = script:
    [
      "${pkgs.tmux}/bin/tmux"
      "-L"
      tmuxSession
      "-f"
      "/dev/null"
      "new-session"
      "-A"
      "-s"
      tmuxSession
    ]
    ++ script
    ++ [";" "set-option" "-t" tmuxSession "status" "off"];
in {
  # Declares dots.services, so the entry below also evaluates when this module
  # is imported on its own. Imported twice (with the rest of dots) it is one module.
  imports = [../../shared/services.nix];

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

    # The handler for the sign-in's final redirect (see the header). Not shown in
    # launchers: it only makes sense with a callback link to pass on. gpclient is
    # named by store path, as in the wrapper, and %u is the link. launch-gui
    # refuses to run as root, which is right: the browser starts it as the user.
    xdg.desktopEntries.globalprotect-callback = {
      name = "GlobalProtect sign-in callback";
      exec = "${gpclient} launch-gui %u";
      mimeType = ["x-scheme-handler/globalprotectcallback"];
      terminal = false;
      noDisplay = true;
    };

    dots.services.globalprotect = {
      label = "GlobalProtect";
      icon = "vpn_key";
      up = inTerminal "up" inTmux;
      down = inTerminal "down" lib.id;
      status = ["${globalprotect}/bin/globalprotect" "status"];
    };
  };
}
