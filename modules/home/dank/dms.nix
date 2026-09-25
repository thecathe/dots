{
  config,
  lib,
  pkgs,
  ...
}: let
  # Keys in settings.json that are state, not config (DMS persists them into
  # the same file as everything else, but they churn independently of any
  # rebuild - e.g. showDock is flipped ad hoc by dank-dock-toggle). Consulted
  # by both dankSettingsCleanFilter (resets them to these defaults on the way
  # into git) and dankMaterialShellSettingsOverlay (seeds a host's real value
  # back in if it's still at the default, e.g. right after a fresh clone).
  # Plain list, not a mkOption: this is a fact about DMS's own schema, not a
  # per-host fact like dank.settingsOverlay.
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
  dankSettingsStateKeys = ["showDock"];
  dankSettingsStateDefaults = {
    showDock = true;
  };

  # git clean filter for settings.json (wired up via .gitattributes +
  # programs.git.settings.filter below): strips dankSettingsStateKeys and
  # customThemeFile back to canonical defaults, desktopWidgetInstances[*].
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
      '.customThemeFile = ""
       | (reduce $keys[] as $k (.; .[$k] = $defaults[$k]))
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
  #
  # Forces the dock visible before every DMS session start (login, reboot,
  # and any restartIfChanged-triggered restart from a rebuild) - wired below
  # via systemd.user.services.dms.Service.ExecStartPre. Deliberately NOT
  # handled via dank.settingsOverlay seeding (unlike desktopWidgetInstances/
  # barConfigs data below): showDock isn't a host fact to seed a default
  # for, it's a "start every session the same way" preference, hidden only
  # ad hoc mid-session via dank-dock-toggle.
  dankResetDockScript = pkgs.writeShellScript "dank-reset-dock" ''
    settingsFile="$HOME/dots/modules/home/dank/settings.json"
    if [ -e "$settingsFile" ]; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq '.showDock = true' "$settingsFile" > "$tmp"
      mv "$tmp" "$settingsFile"
    fi
  '';

  # Seeds this host's real values (customThemeFile, dankSettingsStateKeys,
  # desktopWidgetInstances positions/displayPreferences, barConfigs
  # screenPreferences) into the live settings.json from the tracked host
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
        ${pkgs.jq}/bin/jq \
          --argjson overlay "$(cat "${overlayFile}")" \
          --argjson stateKeys '${builtins.toJSON dankSettingsStateKeys}' \
          --argjson stateDefaults '${builtins.toJSON dankSettingsStateDefaults}' \
          '.customThemeFile = $overlay.customThemeFile
           | (reduce $stateKeys[] as $k (.;
               if (($overlay | has($k)) and (.[$k] == $stateDefaults[$k]))
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
          "$settingsFile" > "$tmpFile"
        if ! cmp -s "$tmpFile" "$settingsFile"; then
          cp "$tmpFile" "$settingsFile"
        fi
      fi
    '';
in {
  options.dank.settingsOverlay = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = ''
      Host-specific values seeded into settings.json on every activation.
      customThemeFile is always overwritten (a purely computed Nix store
      path, nothing of the user's to preserve). Everything else - showDock
      (the only remaining dankSettingsStateKeys entry), desktopWidgetInstances
      position/displayPreferences data (keyed by widget id), and barConfigs
      screenPreferences (keyed by bar id, e.g. [{id: "default",
      screenPreferences: [{name, model}]}, {id: "<other bar id>",
      screenPreferences: [...]}] - only the targeted-screens fragment, not a
      full bar definition, since the rest of a bar's config is genuinely
      shared and tracked normally) - is seeded only where settings.json
      doesn't already carry a real value (still at its canonical default,
      or missing for that output), so a live DMS GUI change always wins
      over this overlay.
      activeDisplayProfile/desktopWidgetGridSettings used to be seeded here
      too, but a DMS update moved them into session.json, which is
      gitignored/host-local and never reset by a checkout - so DMS's own
      normal use keeps them correct per host with no seeding needed; don't
      add them back here.
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
      the same way hosts/nixos/modules/home/monitor.nix does for niri's own
      output config. See hosts/*/modules/home/dank-monitor.json.
    '';
  };

  config = {
    programs.dank-material-shell = {
      enable = true;

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      enableVPN = true; # VPN management widget
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

      # Saves the current clipboard image to ~/Pictures/Saved/NAME.png. DMS-specific
      # (uses dms clipboard paste), so it lives here rather than dots/bin - only
      # exists when this module is enabled, mirroring dank-dock-toggle above. Also
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

    # dank-material-shell's own home-manager module (inputs.dms) defines the
    # "dms" systemd user service that actually launches the shell. Adding to
    # its ExecStartPre here (rather than replacing it) so the dock is always
    # forced visible immediately before DMS starts reading settings.json -
    # see dankResetDockScript above.
    systemd.user.services.dms.Service.ExecStartPre = ["${dankResetDockScript}"];

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
