{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  # Keys in settings.json that are state, not config (DMS persists them into
  # the same file as everything else, but they churn independently of any
  # rebuild - e.g. showDock is flipped ad hoc by dank-dock-toggle). Tracked
  # settings.json never carries these; they live in the gitignored
  # settings.local.json instead. Plain list, not a mkOption: this is a fact
  # about DMS's own schema, not a per-host fact like dank.settingsOverlay.
  dankSettingsStateKeys = ["showDock"];
  dankSettingsStateDefaults = {showDock = true;};
in {
  options.dank.settingsOverlay = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = ''
      Host-specific overrides merged into the tracked settings.json on every
      activation: desktopWidgetInstances position/displayPreferences data
      (keyed by widget id), plus any other top-level key a host needs to set.
      Keeps per-host facts from leaking into the shared file the same way
      hosts/nixos/modules/home/monitor.nix does for niri's own output config.
      See hosts/*/modules/home/dank-monitor.json.
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

    # settings.json's desktopWidgetInstances positions/displayPreferences are
    # per-monitor, and customThemeFile is a Nix store path that stylix computes
    # per-host (see inputs.stylix's dank-material-shell hm target) - both would
    # otherwise leak between hosts or go stale in the shared tracked file (see
    # hosts/nixos/modules/home/monitor.nix for the same concern solved for
    # niri's own output config). Seed this host's own values into the tracked
    # file on every activation, leaving everything else (theme name, font,
    # dock/bar layout, etc) as the untouched shared source of truth.
    #
    # positions/displayPreferences are seed-only-if-missing, not an overwrite:
    # the live file's existing value always wins on conflict (jq's `*` takes
    # the right-hand operand), so once the user drags a widget via the DMS
    # GUI that position sticks across rebuilds - the seed only fills in an
    # output key that isn't there yet (e.g. a fresh clone's empty `positions:
    # {}`, or a displayPreferences still at the generic `["all"]` default).
    # customThemeFile is always overwritten - it's a purely computed value,
    # never user-edited, so there's nothing of the user's to preserve there.
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
            '(. * ($overlay | del(.desktopWidgetInstances))) as $withTopLevel
             | $withTopLevel
             | .desktopWidgetInstances |= map(
                 . as $item
                 | (($overlay.desktopWidgetInstances // {})[$item.id] // {}) as $patch
                 | $item
                   * (if $patch.positions then {positions: ($patch.positions * $item.positions)} else {} end)
                   * (if (($patch.config.displayPreferences? // null) != null) and ($item.config.displayPreferences == ["all"]) then {config: {displayPreferences: $patch.config.displayPreferences}} else {} end)
               )' "$settingsFile" > "$tmpFile"
          mv "$tmpFile" "$settingsFile"
        fi
      '';

    # dankSettingsStateKeys (currently just showDock) are seeded once into the
    # gitignored settings.local.json, same pattern as session.json/session.local.json.
    home.activation.dankMaterialShellSettingsLocal = lib.hm.dag.entryAfter ["writeBoundary"] ''
      target="$HOME/dots/modules/home/dank/settings.local.json"
      if [ ! -e "$target" ]; then
        install -Dm644 ${pkgs.writeText "dank-settings-local-default.json" (builtins.toJSON dankSettingsStateDefaults)} "$target"
      fi
    '';

    # Round-trips dankSettingsStateKeys between the tracked settings.json (which DMS
    # writes to live) and the untracked settings.local.json, so those keys never sit
    # committed in git but DMS still always finds a value:
    # 1. capture - pull whatever DMS last wrote for these keys out of settings.json
    #    into settings.local.json first, so a toggle made earlier this session isn't
    #    reverted by the restore step below.
    # 2. restore - force settings.local.json's value back into settings.json. Right
    #    after this runs the two files agree, so `git diff` on settings.json is clean
    #    for these keys until the next live toggle changes it again.
    home.activation.dankMaterialShellSettingsState =
      lib.hm.dag.entryAfter ["dankMaterialShellSettingsLocal" "dankMaterialShellSettingsOverlay"] ''
        settingsFile="$HOME/dots/modules/home/dank/settings.json"
        localFile="$HOME/dots/modules/home/dank/settings.local.json"
        if [ -e "$settingsFile" ] && [ -e "$localFile" ]; then
          tmpLocal="$(mktemp)"
          ${pkgs.jq}/bin/jq \
            --argjson keys '${builtins.toJSON dankSettingsStateKeys}' \
            --slurpfile settings "$settingsFile" \
            'reduce $keys[] as $k (.; if ($settings[0] | has($k)) then .[$k] = $settings[0][$k] else . end)' \
            "$localFile" > "$tmpLocal"
          mv "$tmpLocal" "$localFile"

          tmpSettings="$(mktemp)"
          ${pkgs.jq}/bin/jq \
            --argjson keys '${builtins.toJSON dankSettingsStateKeys}' \
            --slurpfile local "$localFile" \
            'reduce $keys[] as $k (.; .[$k] = $local[0][$k])' \
            "$settingsFile" > "$tmpSettings"
          mv "$tmpSettings" "$settingsFile"
        fi
      '';
  };
}
