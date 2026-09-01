{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
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
}
