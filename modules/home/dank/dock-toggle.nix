{
  config,
  pkgs,
  ...
}: let
  # Forces the dock visible before every DMS session start (login, reboot,
  # and any restartIfChanged-triggered restart from a rebuild) - wired below
  # via systemd.user.services.dms.Service.ExecStartPre. Deliberately NOT
  # handled via dank.settingsOverlay seeding (unlike desktopWidgetInstances/
  # barConfigs data in dms.nix): showDock isn't a host fact to seed a default
  # for, it's a "start every session the same way" preference, hidden only
  # ad hoc mid-session via dank-dock-toggle.
  #
  # Replaces the file only if jq succeeded AND produced output. On input that
  # is not valid JSON (conflict markers left by a git merge, a half-written
  # file) jq fails and leaves $tmp empty; an unguarded mv would then truncate
  # the live settings.json to 0 bytes. Exits 0 either way: this is dms's
  # ExecStartPre, where a failure would stop the shell from starting.
  dankResetDockScript = pkgs.writeShellScript "dank-reset-dock" ''
    settingsFile="$HOME/dots/modules/home/dank/settings.json"
    if [ -e "$settingsFile" ]; then
      tmp="$(mktemp)"
      trap 'rm -f "$tmp"' EXIT
      if ${pkgs.jq}/bin/jq '.showDock = true' "$settingsFile" > "$tmp" && [ -s "$tmp" ]; then
        mv "$tmp" "$settingsFile"
      else
        echo "dank-reset-dock: $settingsFile is not valid JSON; left untouched" >&2
      fi
    fi
  '';
in {
  # showDock is state, not config: DMS persists it into settings.json with
  # everything else, but dank-dock-toggle flips it ad hoc. Declaring it here
  # has dms.nix's clean filter reset it to true on the way into git, and its
  # overlay seed put a host's real value back (see options.dank.settingsState).
  dank.settingsState.showDock = true;

  # dank-material-shell's own home-manager module (inputs.dms) defines the
  # "dms" systemd user service that actually launches the shell. Adding to
  # its ExecStartPre here (rather than replacing it) so the dock is always
  # forced visible immediately before DMS starts reading settings.json -
  # see dankResetDockScript above.
  systemd.user.services.dms.Service.ExecStartPre = ["${dankResetDockScript}"];

  # Manual dock visibility toggle (bound to Super+Alt+D in niri), independent
  # of dockSmartAutoHide - just flips SettingsData.showDock via DMS's own IPC
  # and toasts (also via DMS's IPC) which way it went, so it can be silenced
  # on demand for anything (games, screenshares) without touching settings.
  home.packages = [
    (pkgs.writeShellScriptBin "dank-dock-toggle" ''
      set -u
      result="$(${config.programs.dank-material-shell.package}/bin/dms ipc call dock toggle)"
      case "$result" in
        DOCK_SHOW_SUCCESS) ${config.programs.dank-material-shell.package}/bin/dms ipc call toast info "Dock shown" ;;
        DOCK_HIDE_SUCCESS) ${config.programs.dank-material-shell.package}/bin/dms ipc call toast info "Dock hidden" ;;
        *) ${config.programs.dank-material-shell.package}/bin/dms ipc call toast warn "Dock toggle: unexpected response ($result)" ;;
      esac
    '')
  ];
}
