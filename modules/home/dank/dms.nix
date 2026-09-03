{
  inputs,
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
  dankSettingsStateKeys = ["activeDisplayProfile" "browserUsageHistory" "desktopWidgetGridSettings" "showDock"];
  dankSettingsStateDefaults = {
    activeDisplayProfile = {};
    browserUsageHistory = {};
    desktopWidgetGridSettings = {};
    showDock = true;
  };

  # git clean filter for settings.json (wired up via .gitattributes +
  # programs.git.settings.filter below): strips dankSettingsStateKeys back to
  # their canonical defaults, and desktopWidgetInstances[*].positions/
  # .config.displayPreferences back to a pristine/no-override shape, on the
  # way INTO git - git applies this to the working-tree content whenever it
  # needs to compute what would be staged/hashed (git add/diff/status/commit),
  # so none of this per-host/session churn ever enters git history, full stop
  # - not even as a one-off snapshot. DMS's live writes to the file (via the
  # out-of-store symlink below) are completely untouched by this; the filter
  # only affects what git sees, never the file on disk.
  #
  # smudge (blob -> working tree, on checkout) is deliberately the identity
  # `cat`: right after a fresh clone/checkout the file just has these
  # canonical defaults, and dankMaterialShellSettingsOverlay below re-seeds
  # this host's real values on the very next activation.
  dankSettingsCleanFilter = pkgs.writeShellScript "dank-settings-clean" ''
    ${pkgs.jq}/bin/jq \
      --argjson keys '${builtins.toJSON dankSettingsStateKeys}' \
      --argjson defaults '${builtins.toJSON dankSettingsStateDefaults}' \
      '(reduce $keys[] as $k (.; .[$k] = $defaults[$k]))
       | .desktopWidgetInstances |= map(
           .positions = {}
           | del(.config.displayPreferences)
         )'
  '';
in {
  options.dank.settingsOverlay = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = ''
      Host-specific values seeded into settings.json on every activation.
      customThemeFile is always overwritten (a purely computed Nix store
      path, nothing of the user's to preserve). Everything else - the
      dankSettingsStateKeys (e.g. desktopWidgetGridSettings,
      activeDisplayProfile) and desktopWidgetInstances position/
      displayPreferences data (keyed by widget id) - is seeded only where
      settings.json doesn't already carry a real value (still at its
      canonical default, or missing for that output), so a live DMS GUI
      change always wins over this overlay.
      None of this data is ever tracked by git in the first place - see
      .gitattributes and dankSettingsCleanFilter above, which strip it back
      to canonical defaults on every git add/diff/status/commit; this
      overlay exists purely to repopulate real per-host values into the live
      file after a fresh clone/checkout. Keeps per-host facts from leaking
      into the shared file the same way hosts/nixos/modules/home/monitor.nix
      does for niri's own output config. See hosts/*/modules/home/dank-monitor.json.
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

      # dank packages
      dgop.package = inputs.dgop.packages.${pkgs.system}.default;

      # niri
      # niri = {
      #   enableKeybinds = true;
      #   enableSpawn = true;
      # };

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

    # Seeds this host's real values into the live settings.json on every
    # activation - the only reason this is needed at all is that the clean
    # filter above means a fresh clone/checkout starts from canonical
    # defaults (empty positions, no displayPreferences, etc), so something
    # has to repopulate real per-host data. Never touches customThemeFile's
    # unconditional-overwrite semantics or the seed-only-where-still-default/
    # missing semantics for everything else - see dank.settingsOverlay's
    # description above for the full rationale.
    home.activation.dankMaterialShellSettingsOverlay = let
      overlay =
        config.dank.settingsOverlay
        // {
          customThemeFile = "${config.programs.dank-material-shell.settings.customThemeFile}";
        };
      overlayFile = pkgs.writeText "dank-settings-overlay.json" (builtins.toJSON overlay);
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        settingsFile="$HOME/dots/modules/home/dank/settings.json"
        if [ -e "$settingsFile" ]; then
          tmpFile="$(mktemp)"
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
               )' \
            "$settingsFile" > "$tmpFile"
          mv "$tmpFile" "$settingsFile"
        fi
      '';
  };
}
