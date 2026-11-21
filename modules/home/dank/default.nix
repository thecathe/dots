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
  ];
  options.dots.dank.enable = lib.mkEnableOption "DankMaterialShell with its menus and settings handling" // {default = true;};
}
