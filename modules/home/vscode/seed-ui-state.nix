{
  lib,
  pkgs,
  profileNames,
}:
# VSCode keeps view layout (which sidebar a view lives in, which containers and
# views are pinned/hidden, and their order) as profile-scoped UI state in
# state.vscdb, not in settings.json. Profiles declared through nix start with no
# UI state, so every workspace on a non-default profile came up with VSCode's
# stock layout. This bootstraps each declared profile's state.vscdb from the
# default profile, which the user curates by hand.
#
# Each profile is seeded once per `version` (tracked by a marker key in its own
# db). Bump `version` to push a changed default layout out again. Existing
# profile dbs are only touched while VSCode is not running, because a running
# window rewrites its in-memory view state over ours on exit; the next switch
# with VSCode closed picks it up.
let
  version = "3";
in
  pkgs.writeShellApplication {
    name = "vscode-seed-ui-state";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils pkgs.procps];
    text = ''
      user_dir="$HOME/.config/Code/User"
      default_db="$user_dir/globalStorage/state.vscdb"
      marker="nix.uiStateSeedVersion"

      if [ ! -f "$default_db" ]; then
        echo "vscode-seed-ui-state: no default profile state at $default_db, skipping" >&2
        exit 0
      fi

      running=0
      if pgrep -u "$USER" -f 'vscode.*--no-sandbox' >/dev/null; then
        running=1
      fi

      # Open Editors / Outline / Timeline had been dragged into the Remote
      # Explorer container (workbench.view.remote), which is never shown, so
      # they could not be toggled on anywhere. Put them back next to the file
      # tree. The default profile is patched in place (VSCode must be closed,
      # same reason as for the profile dbs), then every profile is seeded from
      # it below.
      files_container="workbench.views.service.sidebar.4337fe0b-3e0d-40ce-9701-c62f345cfd7a"
      default_marker="$(sqlite3 "$default_db" "SELECT value FROM ItemTable WHERE key='$marker'" 2>/dev/null || true)"
      if [ "$default_marker" != "${version}" ]; then
        if [ "$running" = 1 ]; then
          echo "vscode-seed-ui-state: VSCode is running, not patching default profile (quit it and switch again)" >&2
          exit 0
        fi
        [ -f "$default_db.pre-nix-patch" ] || cp "$default_db" "$default_db.pre-nix-patch"
        sqlite3 "$default_db" <<SQL
      UPDATE ItemTable SET value = json_set(CAST(value AS TEXT),
        '\$.viewLocations."workbench.explorer.openEditorsView"', '$files_container',
        '\$.viewLocations.outline', '$files_container',
        '\$.viewLocations.timeline', '$files_container')
      WHERE key = 'views.customizations';
      INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('$marker', '${version}');
      SQL
      fi

      for profile in ${lib.escapeShellArgs profileNames}; do
        storage="$user_dir/profiles/$profile/globalStorage"
        db="$storage/state.vscdb"

        if [ -f "$db" ]; then
          current="$(sqlite3 "$db" "SELECT value FROM ItemTable WHERE key='$marker'" 2>/dev/null || true)"
          [ "$current" = "${version}" ] && continue
          if [ "$running" = 1 ]; then
            echo "vscode-seed-ui-state: VSCode is running, not touching $profile (quit it and switch again)" >&2
            continue
          fi
        fi

        mkdir -p "$storage"
        sqlite3 "$db" <<SQL
      CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB);
      ATTACH DATABASE '$default_db' AS d;
      INSERT OR REPLACE INTO ItemTable (key, value)
        SELECT key, value FROM d.ItemTable
        WHERE key IN (
          'views.customizations',
          'workbench.activity.pinnedViewlets2',
          'workbench.activity.placeholderViewlets',
          'workbench.auxiliarybar.pinnedPanels',
          'workbench.auxiliarybar.placeholderPanels',
          'workbench.panel.pinnedPanels',
          'workbench.panel.placeholderPanels'
        )
        OR key LIKE 'workbench.view%.state.hidden'
        OR key LIKE 'workbench.%.views.state.hidden'
        OR key LIKE 'workbench.panel.%.hidden';
      INSERT OR REPLACE INTO ItemTable (key, value) VALUES ('$marker', '${version}');
      SQL
      done
    '';
  }
