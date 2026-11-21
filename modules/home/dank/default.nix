{lib, ...}: {
  imports = [
    ./dms.nix
    ./dock-toggle.nix
    ./search.nix
    ./calendar.nix
    ./curated-menu.nix
    ./services-menu.nix
    ./repos-menu.nix
    ./dictation-status.nix
    # The options used to live under `dank.*`; a host written before they moved keeps working, with a warning.
    (lib.mkRenamedOptionModule ["dank" "settingsState"] ["dots" "dank" "settingsState"])
    (lib.mkRenamedOptionModule ["dank" "settingsOverlayKeys"] ["dots" "dank" "settingsOverlayKeys"])
    (lib.mkRenamedOptionModule ["dank" "settingsOverlay"] ["dots" "dank" "settingsOverlay"])
    (lib.mkRenamedOptionModule ["dank" "curatedMenu" "entries"] ["dots" "dank" "curatedMenu" "entries"])
  ];
  options.dots.dank.enable = lib.mkEnableOption "DankMaterialShell with its menus and settings handling" // {default = true;};
}
