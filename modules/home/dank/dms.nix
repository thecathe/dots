{
  config,
  lib,
  pkgs,
  ...
}: let
  # Keys in settings.json that are state, not config (DMS persists them into
  # the same file as everything else, but they churn independently of any
  # rebuild - e.g. showDock is flipped ad hoc by dank-dock-toggle). Declared
  # through options.dank.settingsState below by whichever module owns the key
  # (today only dock-toggle.nix). Consulted by both dankSettingsCleanFilter
  # (resets them to these defaults on the way into git) and
  # dankMaterialShellSettingsOverlay (seeds a host's real value back in if it's
  # still at the default, e.g. right after a fresh clone).
  #
  # Used to be 4 keys: a DMS update (dms flake input bump in 051068e) moved
  # activeDisplayProfile/desktopWidgetGridSettings into session.json (DMS's
  # own SESSION_MOVED_KEYS) and browserUsageHistory into its cache store
  # (CACHE_MOVED_KEYS) - confirmed by reading the built package's actual
  # SettingsStore.js/SessionData.qml/CacheData.qml, not guessed. They're gone
  # from settings.json's schema outright, not just "omitted while at
  # default", so there's nothing left here for this module to manage: only
  # showDock still lives in settings.json. session.json's own live file
  # (session.local.json below) is gitignored and host-local, so unlike
  # settings.json it's never reset by a checkout - DMS's normal use already
  # keeps its moved-in values correct per host with no seeding needed.
  # (Except desktop widget positions: they moved in the same update, but not
  # through SESSION_MOVED_KEYS, so that list missed them. They start empty in
  # a fresh session; see dankWidgetPositions below.)
  dankSettingsStateDefaults = config.dank.settingsState;
  dankSettingsStateKeys = lib.attrNames dankSettingsStateDefaults;

  # Whole keys that belong to the host, not to the shared file (see
  # options.dank.settingsOverlayKeys). Their canonical default is "absent":
  # DMS omits a key from the file while it is at its own default, so absent is
  # what an unconfigured DMS writes, and what the shared file therefore holds.
  dankSettingsOverlayKeys = config.dank.settingsOverlayKeys;

  # Keys of dank.settingsOverlay with a dedicated stage of their own in the
  # clean filter and the seed (they merge per entry, by id), rather than going
  # through the generic whole-key list above.
  dankSettingsOverlayStructuredKeys = ["desktopWidgetInstances" "barConfigs"];

  # git clean filter for settings.json (wired up via .gitattributes +
  # programs.git.settings.filter below): strips dankSettingsStateKeys and
  # customThemeFile back to canonical defaults, deletes dankSettingsOverlayKeys
  # outright (absent is their canonical default), desktopWidgetInstances[*].
  # positions/.config.displayPreferences back to a pristine/no-override
  # shape, and barConfigs[*].screenPreferences back to per-entry canonical
  # defaults (see the barConfigs stage below), on the way INTO git - git
  # applies this to the working-tree content whenever it needs to compute
  # what would be staged/hashed (git add/diff/status/commit), so none of
  # this per-host/session churn ever enters git history, full stop - not
  # even as a one-off snapshot. DMS's live writes to the file (via the
  # out-of-store symlink below) are completely untouched by this; the
  # filter only affects what git sees, never the file on disk.
  #
  # State keys are deleted and then re-assigned, rather than assigned in
  # place, so they always land last in the object. DMS omits a key from the
  # file while it is at DMS's own default (showDock's is false, so a hidden
  # dock drops the line), and writes it back at its schema position when it
  # isn't. jq's in-place assignment keeps a present key where it is but
  # appends a missing one, which made the cleaned file - and so the diff
  # against HEAD - depend on whether the dock happened to be shown. Pinning
  # the position makes it identical in every state.
  #
  # customThemeFile is handled here as a standalone assignment rather than
  # folded into dankSettingsStateKeys/dankSettingsStateDefaults: unlike
  # showDock, dankMaterialShellSettingsOverlay always force-overwrites it
  # every activation rather than seeding it only if still at the default (see
  # that activation block), so it doesn't share that seed-if-still-default
  # semantics and doesn't belong in a list built for that purpose.
  #
  # barConfigs is kept out of dankSettingsStateKeys too, but for a different
  # reason: each entry mixes genuinely-shared config (widgets, styling -
  # meant to flow into git normally, evolving via ordinary commits on every
  # host) with a host-owned sub-field (screenPreferences, i.e. which physical
  # monitors this bar targets). A whole-key state default would freeze the
  # shared parts too, so it gets its own per-entry-id jq stage below instead:
  # canonical default is ["all"] for the id=="default" entry (matches DMS's
  # own factory bar) and [] for every other entry (matches what DMS itself
  # assigns a freshly-created bar, and - confirmed against DMS's actual
  # SettingsData.qml:barConfigCoversScreen, used by the real per-screen bar
  # loader - means "shown on zero screens" for a bar specifically, unlike the
  # generic per-component screenPreferences path where [] means "all").
  dankSettingsCleanFilter = pkgs.writeShellScript "dank-settings-clean" ''
    ${pkgs.jq}/bin/jq \
      --argjson keys '${builtins.toJSON dankSettingsStateKeys}' \
      --argjson defaults '${builtins.toJSON dankSettingsStateDefaults}' \
      --argjson overlayKeys '${builtins.toJSON dankSettingsOverlayKeys}' \
      '.customThemeFile = ""
       | (reduce $keys[] as $k (.; del(.[$k]) | .[$k] = $defaults[$k]))
       | del(.[$overlayKeys[]])
       | .desktopWidgetInstances |= map(
           .positions = {}
           | del(.config.displayPreferences)
         )
       | .barConfigs |= map(.screenPreferences = (if .id == "default" then ["all"] else [] end))'
  '';

  # smudge (blob -> working tree, on checkout/pull/merge) is the identity
  # `cat`. A tempting alternative is a smudge that reads whatever's currently
  # on disk and merges it with the incoming blob, to stop a pull from ever
  # visibly resetting live data - but that doesn't work: verified empirically
  # (instrumented the smudge command and ran an actual `git checkout -- `)
  # that git unlinks the target file before invoking smudge at all, so by the
  # time smudge runs there is no "current content" left to read. Whatever
  # self-healing needs to happen after a checkout has to happen as a genuinely
  # separate step, after the working tree write completes - see
  # dankSettingsOverlayScript and the dank-settings-repair path unit below,
  # which is exactly that: the same seed-if-still-default/missing logic
  # dankMaterialShellSettingsOverlay already runs at rebuild time, additionally
  # re-run automatically the moment settings.json's content changes for any
  # reason (a checkout, a live DMS write), so the reset window is however long
  # inotify + a jq invocation take, not however long until the next rebuild.

  # Seeds this host's real values (customThemeFile, dankSettingsStateKeys,
  # dankSettingsOverlayKeys, desktopWidgetInstances positions/displayPreferences,
  # barConfigs screenPreferences) into the live settings.json from the tracked host
  # overlay - see options.dank.settingsOverlay's
  # description below for the exact merge semantics per field. Shared between
  # home.activation.dankMaterialShellSettingsOverlay (runs at rebuild time) and
  # the dank-settings-repair systemd path unit below (runs reactively, the
  # instant settings.json's content changes for any reason), since both need
  # the exact same repair.
  #
  # Only overwrites if the computed result actually differs (cmp -s check):
  # without this, dank-settings-repair's own write would retrigger its own
  # path unit forever. Once one real repair has run, a second consecutive run
  # against its own output is a true no-op (nothing left to seed), so the
  # write - and hence the retrigger - stops there.
  #
  # Likewise only writes when jq succeeded and produced output, and exits 0
  # either way (a failing oneshot would count against the path unit's trigger
  # limit and could stop it reacting even after the file is valid again). Without
  # the guard, a settings.json that is not valid JSON at that moment - conflict
  # markers after a git merge, say - made jq fail, leaving an empty $tmpFile that
  # then replaced the live file, truncating it to 0 bytes.
  dankSettingsOverlayScript = let
    overlay =
      config.dank.settingsOverlay
      // {
        customThemeFile = "${config.programs.dank-material-shell.settings.customThemeFile}";
      };
    overlayFile = pkgs.writeText "dank-settings-overlay.json" (builtins.toJSON overlay);
  in
    pkgs.writeShellScript "dank-settings-overlay-seed" ''
      settingsFile="$HOME/dots/modules/home/dank/settings.json"
      if [ -e "$settingsFile" ]; then
        tmpFile="$(mktemp)"
        trap 'rm -f "$tmpFile"' EXIT
        if ${pkgs.jq}/bin/jq \
          --argjson overlay "$(cat "${overlayFile}")" \
          --argjson stateKeys '${builtins.toJSON dankSettingsStateKeys}' \
          --argjson stateDefaults '${builtins.toJSON dankSettingsStateDefaults}' \
          --argjson overlayKeys '${builtins.toJSON dankSettingsOverlayKeys}' \
          '.customThemeFile = $overlay.customThemeFile
           | (reduce $stateKeys[] as $k (.;
               if (($overlay | has($k)) and (.[$k] == $stateDefaults[$k]))
               then .[$k] = $overlay[$k]
               else . end
             ))
           | (reduce $overlayKeys[] as $k (.;
               if (($overlay | has($k)) and (has($k) | not))
               then .[$k] = $overlay[$k]
               else . end
             ))
           | .desktopWidgetInstances |= map(
               . as $item
               | (($overlay.desktopWidgetInstances // {})[$item.id] // {}) as $patch
               | $item
                 * (if $patch.positions then {positions: ($patch.positions * ($item.positions // {}))} else {} end)
               | if ((.config.displayPreferences // null) == null) and (($patch.config.displayPreferences // null) != null)
                 then .config.displayPreferences = $patch.config.displayPreferences
                 else . end
             )
           | .barConfigs |= map(
               . as $bc
               | (if $bc.id == "default" then ["all"] else [] end) as $canonicalDefault
               | ((($overlay.barConfigs // []) | map(select(.id == $bc.id)))[0].screenPreferences) as $ovPrefs
               | if ($ovPrefs != null) and ($bc.screenPreferences == $canonicalDefault)
                 then .screenPreferences = $ovPrefs
                 else . end
             )' \
          "$settingsFile" > "$tmpFile" && [ -s "$tmpFile" ]; then
          if ! cmp -s "$tmpFile" "$settingsFile"; then
            cp "$tmpFile" "$settingsFile"
          fi
        else
          echo "dank-settings-overlay-seed: $settingsFile is not valid JSON; left untouched" >&2
        fi
      fi
    '';

  # Desktop widget positions. DMS 1.6 keeps them in its SESSION file, under
  # desktopWidgetInstancePositions[<instance id>][<screen name>], and reads
  # them from nowhere else: the positions inside settings.json's
  # desktopWidgetInstances are only imported by DMS's migration of a
  # settings.json older than configVersion 15. So the overlay's positions
  # (dankSettingsOverlayScript above still writes them into settings.json, where
  # that migration would find them) reach DMS only through the command below.
  #
  # The record is dank.settingsOverlay.desktopWidgetInstances.<id>.positions as
  # {<id>: {<screen>: {x, y, width, height}}}; empty, so every mode a no-op, on a
  # host whose overlay records none.
  dankWidgetPositionsRecord = pkgs.writeText "dank-widget-positions.json" (builtins.toJSON (
    lib.filterAttrs (_: positions: positions != {}) (
      lib.mapAttrs (_: instance: instance.positions or {}) (config.dank.settingsOverlay.desktopWidgetInstances or {})
    )
  ));

  # One jq program per job. $record is the file above (slurped), $overwrite is
  # true for `apply` and false for `seed`: seeding sets an (instance, screen) pair
  # only where the session has none, so what DMS wrote itself (a drag) is never
  # touched; applying sets every recorded pair, merged over what is there.
  dankWidgetPositionsFill = pkgs.writeText "dank-widget-positions-fill.jq" ''
    ($record[0]) as $rec
    | if ($rec | length) == 0 then .
      else
        .desktopWidgetInstancePositions = (
          reduce ($rec | to_entries[]) as $i (.desktopWidgetInstancePositions // {};
            reduce ($i.value | to_entries[]) as $s (.;
              if $overwrite or ((.[$i.key][$s.key] // null) == null)
              then .[$i.key][$s.key] = ((.[$i.key][$s.key] // {}) * $s.value)
              else . end)))
      end
  '';

  # One row per (widget, screen) that is recorded or set: name, screen, what is
  # recorded, what DMS holds, and how they compare. $names is {id: name}.
  dankWidgetPositionsRows = pkgs.writeText "dank-widget-positions-rows.jq" ''
    def fmt: if . == null then "-" else "\(.x),\(.y) \(.width)x\(.height)" end;
    (.desktopWidgetInstancePositions // {}) as $live
    | ($record[0]) as $rec
    | ([$rec | to_entries[] | .key as $id | .value | to_entries[] | {id: $id, screen: .key}]
       + [$live | to_entries[] | .key as $id | .value | to_entries[]
          | select(($rec[$id][.key] // null) == null) | {id: $id, screen: .key}])
    | .[]
    | . as $p
    | ($rec[$p.id][$p.screen] // null) as $r
    | ($live[$p.id][$p.screen] // null) as $l
    | [ ($names[$p.id] // $p.id), $p.screen, ($r | fmt), ($l | fmt),
        (if $r == null then "not recorded"
         elif $l == null then "not set"
         elif ($r | to_entries | all(.value == $l[.key])) then "same"
         else "differs" end) ]
    | @tsv
  '';

  dankWidgetPositions = pkgs.writeShellApplication {
    name = "dank-widget-positions";
    runtimeInputs = [pkgs.coreutils pkgs.diffutils pkgs.jq pkgs.util-linux];
    text = ''
      session="$HOME/dots/modules/home/dank/session.local.json"
      settings="$HOME/dots/modules/home/dank/settings.json"
      record="${dankWidgetPositionsRecord}"
      tmp=""
      trap 'rm -f "$tmp"' EXIT

      usage() {
        cat <<'EOF'
      Usage: dank-widget-positions [status | apply [-n|--dry-run] [--no-restart] | seed]

      Compares the desktop widget positions this host records (dank-monitor.json
      in the hosts repo, as of the last rebuild) with the ones DMS holds in its
      session file.

        status   show both side by side (the default)
        apply    set DMS's positions to the recorded ones, for every recorded
                 widget and screen. DMS reads that file only when it starts and
                 writes its own copy back at its next save, so apply stops
                 dms.service while it writes and starts it again (a few seconds
                 without the shell); --no-restart leaves DMS alone, and then it
                 has to be restarted by hand or it undoes the change.
                 -n shows what would change and changes nothing
        seed     set only the positions DMS has none for; quiet, and what a
                 rebuild runs, so a position DMS wrote itself is never touched
      EOF
      }

      # The session file with the recorded positions applied ($1 = true: all of
      # them, false: only the missing ones), written beside it and renamed over
      # it, so DMS (which watches the file) never reads half of one. Returns 0
      # when it changed something, 1 when there was nothing to change, 2 when the
      # file was left alone because it could not be read or rewritten.
      write_session() {
        [ -f "$session" ] || return 1
        tmp=$(mktemp "$session.XXXXXX")
        if jq --slurpfile record "$record" --argjson overwrite "$1" -f ${dankWidgetPositionsFill} "$session" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then
          if cmp -s <(jq -S . "$tmp") <(jq -S . "$session"); then
            return 1
          fi
          chmod --reference="$session" "$tmp"
          mv -f "$tmp" "$session"
          return 0
        fi
        echo "dank-widget-positions: $session is not valid JSON or could not be rewritten; left untouched" >&2
        return 2
      }

      rows() {
        local names='{}'
        if [ -f "$settings" ]; then
          names=$(jq -c '[.desktopWidgetInstances[]? | select(.id != null) | {(.id): (.name // .id)}] | add // {}' "$settings" 2>/dev/null) || names='{}'
        fi
        jq -r --slurpfile record "$record" --argjson names "$names" -f ${dankWidgetPositionsRows} "$session"
      }

      status() {
        if [ ! -f "$session" ]; then
          echo "No session file at $session yet (DMS has not run here)."
          return 0
        fi
        local out
        if ! out=$(rows); then
          echo "dank-widget-positions: $session is not valid JSON" >&2
          return 1
        fi
        if [ -z "$out" ]; then
          echo "Nothing recorded for this host, and DMS has no widget positions."
          return 0
        fi
        { printf 'WIDGET\tSCREEN\tRECORDED\tDMS HOLDS\tSTATE\n'; printf '%s\n' "$out"; } | column -t -s "$(printf '\t')"
      }

      dms_active() {
        systemctl --user is-active --quiet dms.service 2>/dev/null
      }

      # DMS loads its session file when it starts and writes the whole of its own
      # copy back at its next save (tested: an outside write, atomic or in place,
      # is neither noticed nor kept; and it saves nothing on its way out), so
      # a change made behind its back is lost. Hence the stop around the write.
      apply() {
        local dry=$1 restart=$2 pending=0 state rc=0 stopped=false running=false
        [ -f "$session" ] || { echo "No session file at $session yet (DMS has not run here)."; return 0; }
        status
        while IFS=$'\t' read -r _ _ _ _ state; do
          case $state in
            differs | "not set") pending=$((pending + 1)) ;;
          esac
        done < <(rows)
        if [ "$pending" -eq 0 ]; then
          echo "Nothing to change."
          return 0
        fi
        if dms_active; then running=true; fi
        if [ "$dry" = true ]; then
          echo "Would set $pending position(s) to the recorded ones. Nothing changed."
          if [ "$running" = true ] && [ "$restart" = true ]; then
            echo "DMS would be stopped for the write and started again."
          fi
          return 0
        fi
        if [ "$running" = true ] && [ "$restart" = true ]; then
          if ! systemctl --user stop dms.service; then
            echo "dank-widget-positions: could not stop dms.service; nothing changed" >&2
            return 1
          fi
          stopped=true
        fi
        write_session true || rc=$?
        # Never leave the shell stopped, whatever the write did.
        if [ "$stopped" = true ] && ! systemctl --user start dms.service; then
          echo "dank-widget-positions: could not start dms.service again; start it by hand" >&2
          return 1
        fi
        case $rc in
          0) ;;
          1)
            echo "Nothing to change."
            return 0
            ;;
          *) return 1 ;;
        esac
        if [ "$stopped" = true ]; then
          echo "Set $pending position(s) to the recorded ones. DMS was restarted to read them."
        elif [ "$running" = true ]; then
          echo "Set $pending position(s) to the recorded ones, but DMS is running and keeps its own copy:" \
            "restart it now (systemctl --user restart dms), or it will overwrite them at its next save."
        else
          echo "Set $pending position(s) to the recorded ones. DMS is not running; it reads them when it starts."
        fi
      }

      case "''${1:-status}" in
        status) status ;;
        apply)
          dry=false
          restart=true
          shift
          for arg in "$@"; do
            case $arg in
              -n | --dry-run) dry=true ;;
              --no-restart) restart=false ;;
              *) usage >&2; exit 2 ;;
            esac
          done
          apply "$dry" "$restart"
          ;;
        seed)
          # Always succeeds: it runs inside the activation script.
          write_session false || true
          ;;
        -h | --help | help) usage ;;
        *) usage >&2; exit 2 ;;
      esac
    '';
  };
in {
  options.dank.settingsState = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    example = {showDock = true;};
    description = ''
      settings.json keys that are state rather than config, each with the
      canonical default it is reset to on the way into git (see
      dankSettingsCleanFilter) and that a host's real value is seeded over
      when the live file is still at it (see dankSettingsOverlayScript). A
      fact about DMS's own schema, not a per-host fact: declared by the module
      that owns the key (dock-toggle.nix declares showDock), where the host's
      value, if any, then goes in dank.settingsOverlay.
    '';
  };

  options.dank.settingsOverlayKeys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = ["controlCenterWidgets"];
    description = ''
      Top-level settings.json keys whose whole value belongs to the host, not
      to the shared file. Adding a key here is all it takes to make it
      host-specific: the clean filter deletes it on the way into git (so the
      shared file never carries it), and the overlay seeds the host's value
      from dank.settingsOverlay.<key> when the live file has none. Absent is
      the canonical default because DMS omits a key from the file while it is
      at its own default. Like everything in the overlay, a live DMS GUI change
      wins: the key stays as DMS wrote it until the host's own copy in
      dank.settingsOverlay is updated by hand. (So resetting the key to DMS's
      default in the GUI removes it, and the host's value comes back.)

      Only for keys that are replaced as a whole. Keys merged per entry
      (desktopWidgetInstances, barConfigs) and state keys (dank.settingsState)
      have their own handling. A definition here is a normal one, so a host
      appends with a plain assignment; dms.nix sets the base list.
    '';
  };

  options.dank.settingsOverlay = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = ''
      Host-specific values seeded into settings.json on every activation.
      customThemeFile is always overwritten (a purely computed Nix store
      path, nothing of the user's to preserve). Everything else - showDock
      (a dank.settingsState key, declared by dock-toggle.nix), every key
      named in dank.settingsOverlayKeys (whole values, e.g.
      controlCenterWidgets), desktopWidgetInstances
      position/displayPreferences data (keyed by widget id), and barConfigs
      screenPreferences (keyed by bar id, e.g. [{id: "default",
      screenPreferences: [{name, model}]}, {id: "<other bar id>",
      screenPreferences: [...]}] - only the targeted-screens fragment, not a
      full bar definition, since the rest of a bar's config is genuinely
      shared and tracked normally) - is seeded only where settings.json
      doesn't already carry a real value (still at its canonical default,
      or missing for that output), so a live DMS GUI change always wins
      over this overlay.
      A key that none of those handle is a build error (see the assertions
      below), rather than being silently ignored.
      activeDisplayProfile/desktopWidgetGridSettings used to be seeded here
      too, but a DMS update moved them into session.json, which is
      gitignored/host-local and never reset by a checkout - so DMS's own
      normal use keeps them correct per host with no seeding needed; don't
      add them back here.
      The same update moved the desktop widget POSITIONS into session.json,
      and DMS reads them only from there; the positions seeded into
      settings.json are only for DMS's migration of an old settings file. So
      the recorded positions also reach the session file, by the
      dank-widget-positions command: a rebuild fills in the (widget, screen)
      pairs the session has none for (which, since DMS stores a default the
      first time it shows a widget on a screen, means a host that has not
      shown it yet), and `dank-widget-positions apply` sets them all to the
      record on request, restarting DMS around the write because DMS reads
      the session only when it starts. displayPreferences are still read from
      settings.json.
      None of this data is ever tracked by git in the first place - see
      .gitattributes and dankSettingsCleanFilter above, which strip it back
      to canonical defaults on every git add/diff/status/commit. This overlay
      (applied by dankSettingsOverlayScript) exists purely to repopulate real
      per-host values into the live file - both at rebuild time
      (home.activation.dankMaterialShellSettingsOverlay) and reactively,
      within moments of settings.json's content changing for any reason (the
      dank-settings-repair systemd path unit), since a git checkout/pull can
      reset it to canonical defaults at any time and there's no way to stop
      that at the git-filter level - see dankSettingsOverlayScript's comment
      above for why. Keeps per-host facts from leaking into the shared file
      the same way the hosts repo's nixos/modules/home/monitor.nix does for niri's own
      output config. See <host>/modules/home/dank-monitor.json in the hosts repo.
    '';
  };

  config = {
    # Whole settings.json keys that are host-specific (options.dank.
    # settingsOverlayKeys): to make another one so, add its name here and put
    # the value in the host's dank-monitor.json under the same key.
    dank.settingsOverlayKeys = [
      # The control centre's tiles, their order and widths: depends on the
      # hardware (a battery tile on a laptop, disk usage on the desktop).
      "controlCenterWidgets"
    ];

    # The overlay is read by name, so a key that nothing handles would be
    # accepted by the option type and then silently ignored (as
    # controlCenterWidgets was, for weeks, before it was listed above).
    assertions = let
      handled = dankSettingsOverlayStructuredKeys ++ dankSettingsStateKeys ++ dankSettingsOverlayKeys;
      stray = lib.subtractLists handled (lib.attrNames config.dank.settingsOverlay);
      both = lib.intersectLists dankSettingsStateKeys dankSettingsOverlayKeys;
    in [
      {
        assertion = stray == [];
        message = ''
          dank.settingsOverlay has keys nothing reads: ${lib.concatStringsSep ", " stray}.
          Add a whole-value key to dank.settingsOverlayKeys (dms.nix), or remove it from the host's dank-monitor.json.
          (customThemeFile is always computed from the theme, so a host cannot set it.)
        '';
      }
      {
        assertion = both == [];
        message = "dank.settingsState and dank.settingsOverlayKeys both list: ${lib.concatStringsSep ", " both}. A key is one or the other.";
      }
    ];

    programs.dank-material-shell = {
      enable = true;

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      # VPN widget deps - off: all this flag does is put nixpkgs' glib +
      # networkmanager in the profile (nothing is configured by it, and the
      # widget itself only ever drives NetworkManager profiles that already
      # exist). On the Ubuntu host that nix nmcli (1.58.x) shadows /usr/bin's
      # and mismatches the system daemon (1.54.x); the widget's `.ovpn`/`.conf`
      # import shells out to whichever `nmcli` is first on PATH. The option
      # defaults to true, so it has to be set explicitly rather than removed.
      enableVPN = false;
      enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      enableAudioWavelength = false; # Audio visualizer (cava) - disabled: continuous audio capture + redraw suspected of contributing to pipewire xruns and compositor flicker
      enableCalendarEvents = true; # Calendar integration (khal)

      # DMS plugins, previously "installed" ad hoc via the settings GUI (which
      # just writes into a local, untracked runtime dir the settings.json
      # snapshot can't capture, so nothing came with a fresh clone). Declared
      # here instead - dms-plugin-registry's module (wired in flake.nix)
      # already supplies `src` per plugin name via fetchgit; enabling by name
      # is all that's needed.
      plugins = {
        dankDesktopWeather.enable = true;
        dankClight.enable = true;
        dankLauncherKeys.enable = true;
        dankPomodoroTimer.enable = true;
        # dankHyprlandWindows ("hyprland window switcher") is Hyprland-only
        # and won't function under niri, which both hosts use now - niriWindows
        # is the niri-native equivalent for switching between open windows.
        niriWindows.enable = true;
        # Daily Bing wallpaper daemon. deleteOld = false + Gnome-compat naming
        # turns its own image dir into a free "recents" pool (date-prefixed
        # filenames, never overwritten) - retention is handled separately by
        # bing-wallpaper-gc (modules/home/wallpaper) rather than this plugin's
        # own single-previous-file cleanup.
        wallpaperBing = {
          enable = true;
          settings = {
            notifications = true;
            deleteOld = false;
            GnomeExtensionBingWallpaperCompatibility = true;
            enableDailyRefresh = true;
            dailyRefreshTime = "09:00";
          };
        };

        # Launcher (Spotlight) plugins. calculator/converter need nothing
        # extra (calculator can optionally use qalc/numbat engines, not
        # installed).
        calculator.enable = true;
        converter.enable = true;
        # Live `fd` search behind the `,` trigger - no index or inotify
        # watches, so it covers the repos under ~/Documents/git that dsearch
        # (search.nix) deliberately doesn't index. `fd` itself is in
        # home.packages below.
        fdSearch.enable = true;

        # DankBar widgets - enabling only makes them available; they show up
        # once added to a bar in settings.json (or, for screenOff, also as a
        # control-center tile). dankDiskUsage covers disk, ZFS and the Nix
        # store. (nixMonitor was dropped: its defaults are placeholder
        # commands and nothing configured it, so it never showed real data.)
        dankDiskUsage.enable = true;
        # Shells out to udisksctl/lsblk/parted/mkfs.* and polkit, all of
        # which come from the host (apt on Ubuntu, NixOS udisks2/polkit).
        usbManager.enable = true;
        screenOff.enable = true;
      };

      clipboardSettings = {
        maxHistory = 25;
        maxEntrySize = 5242880;
        autoClearDays = 1;
        clearAtStartup = true;
        disabled = false;
        disableHistory = false;
        disablePersist = true;
      };

      # systemd service for auto-start
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
    };

    home.packages = [
      # Runtime dependency of the fdSearch launcher plugin (programs.dank-
      # material-shell.plugins above); not packaged by the registry module.
      pkgs.fd

      # Shows, or re-applies by hand, this host's recorded desktop widget
      # positions (see dankWidgetPositions above); the rebuild runs its `seed`.
      dankWidgetPositions

      # Saves the current clipboard image to ~/Pictures/Saved/NAME.png. DMS-specific
      # (uses dms clipboard paste), so it lives here rather than dots/bin - only
      # exists when this module is enabled, like dank-dock-toggle (dock-toggle.nix). Also
      # bound to Ctrl+Alt+S in niri (modules/home/wm/niri/config.kdl), which
      # supplies a timestamp as NAME - see the comment there for why that bind
      # isn't DMS-gated.
      #
      # `dms clipboard paste`'s output format depends on what it's reading, not
      # just fixed - confirmed by reproducing live (niri msg action
      # screenshot-screen, then immediately dms clipboard paste): a genuinely
      # fresh clipboard offer (e.g. right after a screenshot, before DMS's own
      # history has ingested it) gets dumped as raw PNG bytes on stdout, while a
      # history-backed entry (e.g. after clicking it in DMS's clipboard widget)
      # instead prints a ~/.cache/dms/clipboard/<id>.png path string. Piping
      # straight into `cp` (as if it were always a path) silently fails on the
      # first case - cp errors on the binary "path", and with nothing checking
      # its exit code the notification below still claimed success with no file
      # ever written. Handled here by sniffing the PNG magic bytes and branching:
      # write raw bytes directly, or treat the output as a path and copy that.
      (pkgs.writeShellScriptBin "clipsave" ''
        set -u
        name="''${1:-}"
        if [ -z "$name" ]; then
          echo "usage: clipsave NAME" >&2
          exit 1
        fi
        dest="$HOME/Pictures/Saved/''${name}.png"
        mkdir -p "$(dirname "$dest")"

        raw="$(mktemp)"
        trap 'rm -f "$raw"' EXIT
        ${config.programs.dank-material-shell.package}/bin/dms clipboard paste > "$raw"

        magic="$(head -c4 "$raw" | od -An -tx1 | tr -d ' \n')"
        if [ "$magic" = "89504e47" ]; then
          mv "$raw" "$dest"
        else
          path="$(tr -d '\n' < "$raw")"
          if [ -n "$path" ] && [ -f "$path" ]; then
            cp "$path" "$dest"
          fi
        fi

        if [ -s "$dest" ]; then
          action="$(${pkgs.libnotify}/bin/notify-send -a clipsave -t 4000 -A "default=Open folder" "Clipboard image saved" "$dest")"
          if [ "$action" = "default" ]; then
            ${pkgs.nautilus}/bin/nautilus --select "$dest"
          fi
        else
          ${pkgs.libnotify}/bin/notify-send -a clipsave -u critical -t 4000 "clipsave failed" "No image found on the clipboard"
          exit 1
        fi
      '')
    ];

    # Registers the clean/smudge commands for the "dank-settings" filter named
    # in .gitattributes, in this user's own ~/.config/git/config rather than
    # the repo. A cloned .gitattributes can only ever name a filter, never
    # supply the command to run (git deliberately keeps the two separate, for
    # exactly this security reason) - so this is what actually makes the
    # filter live, per host, with zero manual setup after a clone.
    programs.git.settings.filter."dank-settings" = {
      clean = "${dankSettingsCleanFilter}";
      smudge = "${pkgs.coreutils}/bin/cat";
    };

    # Restart DMS when any plugin or plugin setting changes. DMS reads
    # plugin_settings.json once at startup: its file watch never fires on a
    # rebuild, because home-manager swaps the symlink and the old store file it
    # watches never changes. A plugin's pluginData then stays stale (an added
    # plugin sees {} even after `dms ipc call plugins reload`), and a new
    # plugin dir was not picked up either. Listing every plugin's source and
    # settings in a file referenced by the unit makes the unit change whenever
    # they do, so the switch restarts DMS (restartIfChanged above).
    systemd.user.services.dms.Unit.X-Restart-Triggers = [
      (pkgs.writeText "dms-plugins.json" (builtins.toJSON (lib.mapAttrs (_: p: {
        inherit (p) settings;
        src = "${p.src}";
      }) (lib.filterAttrs (_: p: p.enable) config.programs.dank-material-shell.plugins))))
    ];

    # settings.json is tracked directly: symlinked straight into the dots repo so the
    # DMS settings app can write to it (Qt's QSaveFile resolves symlinks and writes
    # through them), instead of nix's default read-only nix-store-backed symlink.
    # mkForce: stylix's dank-material-shell integration also injects a small settings
    # fragment (theme name/font/transparency); this wins so the tracked file is the
    # single source of truth. Re-run stylix's dank-material-shell target and copy any
    # font/transparency values you want to keep back into settings.json if you change them.
    xdg.configFile."DankMaterialShell/settings.json".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dots/modules/home/dank/settings.json"
    );

    # session.json churns on almost every UI interaction, so the live file is gitignored
    # (modules/home/dank/session.local.json) and only seeded once from the tracked
    # modules/home/dank/session.json default, mirroring modules/home/claude/default.nix.
    home.activation.dankMaterialShellSession = lib.hm.dag.entryAfter ["writeBoundary"] ''
      target="$HOME/dots/modules/home/dank/session.local.json"
      if [ ! -e "$target" ]; then
        install -Dm644 "$HOME/dots/modules/home/dank/session.json" "$target"
      fi
    '';
    xdg.stateFile."DankMaterialShell/session.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dots/modules/home/dank/session.local.json";

    # DMS reads desktop widget positions only from that session file, and a
    # fresh one has none. Fill in the positions the host records
    # (dank-monitor.json), but only the ones the session lacks: a position DMS
    # wrote itself (a drag) always wins, so a rebuild never moves a widget.
    # Limits, all tested against the real DMS: DMS stores a default for a
    # widget the first time it shows it on a screen, so this only gets in first
    # on a host that has not shown it yet (a new host's first rebuild; DMS is
    # started after activation); and DMS keeps its own copy and writes it all
    # back at its next save, so a seed written while it runs is lost. To make
    # the session follow the record after editing it, run
    # `dank-widget-positions apply`, which restarts DMS around the write.
    home.activation.dankMaterialShellWidgetPositions =
      lib.hm.dag.entryAfter ["dankMaterialShellSession"] "${dankWidgetPositions}/bin/dank-widget-positions seed";

    # Seeds this host's real values into the live settings.json at rebuild
    # time - the only reason this is needed at all is that the clean filter
    # above means a fresh clone/checkout starts from canonical defaults
    # (empty positions, no displayPreferences, etc), so something has to
    # repopulate real per-host data. See dank.settingsOverlay's description
    # above for the full rationale, and dankSettingsOverlayScript's comment
    # for why this same repair also runs reactively via a path unit, not just
    # here at rebuild time.
    home.activation.dankMaterialShellSettingsOverlay =
      lib.hm.dag.entryAfter ["writeBoundary"] "${dankSettingsOverlayScript}";

    # Reactive counterpart to dankMaterialShellSettingsOverlay: fires
    # dankSettingsOverlayScript within moments of settings.json's content
    # actually changing on disk, for ANY reason - a `git checkout`/pull
    # resetting it to canonical defaults, or DMS's own live writes - rather
    # than only at the next `home-manager switch`. PathModified triggers on
    # writes (IN_CLOSE_WRITE); dankSettingsOverlayScript's own cmp -s guard
    # is what stops this from retriggering itself forever (its own write, if
    # any, produces content that's a no-op patch of itself on the next run).
    systemd.user.paths.dank-settings-repair = {
      Unit.Description = "Watch DankMaterialShell settings.json for host-data resets";
      Path.PathModified = ["%h/dots/modules/home/dank/settings.json"];
      Install.WantedBy = ["default.target"];
    };
    systemd.user.services.dank-settings-repair = {
      Unit.Description = "Reseed DankMaterialShell settings.json's host-specific data";
      Service = {
        Type = "oneshot";
        ExecStart = "${dankSettingsOverlayScript}";
      };
    };
  };
}
