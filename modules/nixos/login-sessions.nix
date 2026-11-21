# dots.loginSessions: which session GDM starts for each account, e.g.
#
#   dots.loginSessions = { alice = "niri"; bob = "gnome"; };
#
# Left empty (the default) the module does nothing and GDM behaves as nixpkgs
# configures it. Session names are the .desktop file names under
# wayland-sessions/ and xsessions/ ("gnome", "niri", ...); an unknown name or
# user fails the build rather than the login.
#
# Why this is not just services.displayManager.defaultSession: nixpkgs'
# programs.niri sets that to "niri" (mkDefault), and with any defaultSession set
# GDM's pre-start runs nixpkgs' `set-session`, which writes that one session into
# EVERY normal account's AccountsService record on every start. That cannot give
# two accounts two sessions, and it overwrites whatever either of them picked.
# So this module turns that default off and, in the same pre-start slot, sets
# each listed account's session itself.
#
# It sets only the session, through AccountsService's own D-Bus methods (as
# `set-session` does), and never rewrites the account's file: the same record
# holds the avatar and language, which a whole-file rewrite would reset. The
# listed sessions are enforced at every start of the login screen (boot, or
# `systemctl restart display-manager`); a session picked from the gear icon lasts
# until then. `nixos-rebuild switch` does not restart the login screen, so a
# change here shows at the next boot.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.dots.loginSessions;
  inherit (config.services.displayManager) sessionData;

  setLoginSessions = pkgs.writeShellApplication {
    name = "set-login-sessions";
    runtimeInputs = [pkgs.systemd];
    text = ''
      # set-login-sessions USER=SESSION...
      # Never fails: a login screen that does not start is worse than a wrong session.
      accounts=org.freedesktop.Accounts
      for pair in "$@"; do
        user=''${pair%%=*}
        session=''${pair#*=}
        if [ -e "${sessionData.desktops}/share/wayland-sessions/$session.desktop" ]; then
          type=wayland
        elif [ -e "${sessionData.desktops}/share/xsessions/$session.desktop" ]; then
          type=x11
        else
          echo "set-login-sessions: no session file for '$session' ($user)" >&2
          continue
        fi
        if ! out=$(busctl call "$accounts" /org/freedesktop/Accounts "$accounts" FindUserByName s "$user"); then
          echo "set-login-sessions: AccountsService does not know '$user'" >&2
          continue
        fi
        object=$(cut -d'"' -f2 <<<"$out")
        set_property() {
          busctl call "$accounts" "$object" "$accounts.User" "$1" s "$2" >/dev/null ||
            echo "set-login-sessions: $1 $2 failed for '$user'" >&2
        }
        [ "$type" = x11 ] && set_property SetXSession "$session"
        set_property SetSession "$session"
        set_property SetSessionType "$type"
      done
    '';
  };
in {
  options.dots.loginSessions = mkOption {
    type = types.attrsOf types.str;
    default = {};
    example = {
      alice = "niri";
      bob = "gnome";
    };
    description = "Account name -> login session GDM starts for it, enforced at every start of the login screen.";
  };

  config = lib.mkIf (cfg != {}) {
    assertions =
      lib.mapAttrsToList (user: session: {
        assertion = config.users.users ? ${user} && lib.elem session sessionData.sessionNames;
        message = "dots.loginSessions.${user} = \"${session}\": needs an account named ${user} and one of the installed sessions (${lib.concatStringsSep ", " sessionData.sessionNames}).";
      })
      cfg;

    # No defaultSession, so GDM's own pre-start does not run `set-session`.
    services.displayManager.defaultSession = null;

    systemd.services.display-manager.preStart = ''
      ${lib.getExe setLoginSessions} ${lib.escapeShellArgs (lib.mapAttrsToList (user: session: "${user}=${session}") cfg)}
    '';
  };
}
